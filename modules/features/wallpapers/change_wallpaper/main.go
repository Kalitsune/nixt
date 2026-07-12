package main

import (
	"flag"
	"fmt"
	"github.com/h2non/bimg"
	"io/fs"
	"log"
	"math/rand"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strings"
)

var Extensions = []string{".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".gif", ".heic", ".avif"}

func orDefault(value string, def string) string {
	if value == "" {
		return def
	}
	return value
}

func main() {
	root_dir := flag.String("root-dir", orDefault(os.Getenv("WALLPAPER_ROOT"), "."), "Path to the wallpaper reposiory")
	filter := flag.String("filter", "", "Select specific wallpaper collections (e.g. \"digital-art/cosmic-journeys\")")
	number := flag.Int("number", -1, "If set, selects the n-th file, otherwise defaults to random.")
	output := flag.String("output", "", "Path where the wallpaper should be set (supported formats: png, jpg, jpeg, gif)")

	flag.Parse()

	var candidates = list_candidates(path.Join(*root_dir, *filter))

	if len(candidates) == 0 {
		log.Fatal("Couldn't find any wallpaper, please ensure that your filter is valid!")
	}

	// Define a random number
	if *number == -1 {
		*number = rand.Int()
	}

	// Pick the selected Image
	image := candidates[*number%len(candidates)]

	if *output == "" {
		// Print the image path
		fmt.Printf("%s", image)
	} else {
		// Copy the image to the target format
		convertImage(image, *output)
	}
}

func list_candidates(root_dir string) []string {
	candidates := []string{}

	err := filepath.WalkDir(root_dir, func(path string, d fs.DirEntry, err error) error {
		if d != nil && !d.IsDir() && slices.Contains(Extensions, filepath.Ext(d.Name())) {
			candidates = append(candidates, path)
		}

		return nil // no error :D
	})
	if err != nil {
		log.Fatal("Failed to ")
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
