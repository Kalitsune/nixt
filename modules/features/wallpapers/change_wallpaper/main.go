package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"math/rand"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strings"

	"github.com/h2non/bimg"
)

var Extensions = []string{".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".gif", ".heic", ".avif"}

func orDefault(value string, def string) string {
	if value == "" {
		return def
	}
	return value
}

type githubSource struct {
	owner string
	repo  string
}

func parseSource(src string) (isGithub bool, gh githubSource, localPath string) {
	if strings.HasPrefix(src, "github:") {
		parts := strings.SplitN(strings.TrimPrefix(src, "github:"), "/", 2)
		if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
			log.Fatal("Invalid GitHub source, expected format: github:owner/repo")
		}
		return true, githubSource{owner: parts[0], repo: parts[1]}, ""
	}
	return false, githubSource{}, src
}

type treeEntry struct {
	Path string `json:"path"`
	Type string `json:"type"`
}

type treeResponse struct {
	Tree []treeEntry `json:"tree"`
}

func githubRequest(url string) (*http.Response, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	if token := os.Getenv("GITHUB_TOKEN"); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	return http.DefaultClient.Do(req)
}

func listGithubCandidates(gh githubSource, filter string) []string {
	url := fmt.Sprintf("https://api.github.com/repos/%s/%s/git/trees/HEAD?recursive=1", gh.owner, gh.repo)
	resp, err := githubRequest(url)
	if err != nil {
		log.Fatalf("Failed to query GitHub API: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Fatalf("GitHub API returned status %d", resp.StatusCode)
	}

	var tree treeResponse
	if err := json.NewDecoder(resp.Body).Decode(&tree); err != nil {
		log.Fatalf("Failed to parse GitHub API response: %v", err)
	}

	var candidates []string
	for _, entry := range tree.Tree {
		if entry.Type != "blob" {
			continue
		}
		if filter != "" && !strings.HasPrefix(entry.Path, filter) {
			continue
		}
		if slices.Contains(Extensions, strings.ToLower(filepath.Ext(entry.Path))) {
			candidates = append(candidates, entry.Path)
		}
	}
	return candidates
}

func downloadGithubImage(gh githubSource, filePath string) (string, error) {
	url := fmt.Sprintf("https://raw.githubusercontent.com/%s/%s/HEAD/%s", gh.owner, gh.repo, filePath)
	resp, err := githubRequest(url)
	if err != nil {
		return "", fmt.Errorf("download failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("download returned status %d", resp.StatusCode)
	}

	ext := filepath.Ext(filePath)
	tmp, err := os.CreateTemp("", "wallpaper-*"+ext)
	if err != nil {
		return "", fmt.Errorf("create temp file: %w", err)
	}
	defer tmp.Close()

	if _, err := io.Copy(tmp, resp.Body); err != nil {
		os.Remove(tmp.Name())
		return "", fmt.Errorf("write temp file: %w", err)
	}
	return tmp.Name(), nil
}

func main() {
	root_dir := flag.String("root-dir", orDefault(os.Getenv("WALLPAPER_ROOT"), "."), "Path to the wallpaper repository, or github:owner/repo")
	filter := flag.String("filter", "", "Select specific wallpaper collections (e.g. \"digital-art/cosmic-journeys\")")
	number := flag.Int("number", -1, "If set, selects the n-th file, otherwise defaults to random.")
	output := flag.String("output", "", "Path where the wallpaper should be set (supported formats: png, jpg, jpeg, gif)")

	flag.Parse()

	isGithub, gh, localPath := parseSource(*root_dir)

	var candidates []string
	if isGithub {
		candidates = listGithubCandidates(gh, *filter)
	} else {
		candidates = list_candidates(path.Join(localPath, *filter))
	}

	if len(candidates) == 0 {
		log.Fatal("Couldn't find any wallpaper, please ensure that your filter is valid!")
	}

	if *number == -1 {
		*number = rand.Int()
	}

	picked := candidates[*number%len(candidates)]

	if isGithub {
		tmpPath, err := downloadGithubImage(gh, picked)
		if err != nil {
			log.Fatalf("Failed to download wallpaper: %v", err)
		}
		if *output == "" {
			fmt.Printf("%s", tmpPath)
		} else {
			if err := convertImage(tmpPath, *output); err != nil {
				os.Remove(tmpPath)
				log.Fatalf("Failed to convert wallpaper: %v", err)
			}
			os.Remove(tmpPath)
		}
	} else {
		if *output == "" {
			fmt.Printf("%s", picked)
		} else {
			convertImage(picked, *output)
		}
	}
}

func list_candidates(root_dir string) []string {
	candidates := []string{}

	err := filepath.WalkDir(root_dir, func(path string, d fs.DirEntry, err error) error {
		if d != nil && !d.IsDir() && slices.Contains(Extensions, filepath.Ext(d.Name())) {
			candidates = append(candidates, path)
		}

		return nil
	})
	if err != nil {
		log.Fatal("Failed to list wallpapers")
	}

	return candidates
}

func convertImage(srcPath, dstPath string) error {
	buf, err := bimg.Read(srcPath)
	if err != nil {
		return err
	}

	ext := strings.ToLower(filepath.Ext(dstPath))
	var typ bimg.ImageType
	switch ext {
	case ".jpg", ".jpeg":
		typ = bimg.JPEG
	case ".png":
		typ = bimg.PNG
	case ".webp":
		typ = bimg.WEBP
	case ".gif":
		typ = bimg.GIF
	default:
		return fmt.Errorf("unsupported: %s", ext)
	}

	newImg, err := bimg.NewImage(buf).Convert(typ)
	if err != nil {
		return err
	}
	return bimg.Write(dstPath, newImg)
}
