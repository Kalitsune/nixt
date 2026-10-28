package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"math/rand"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/h2non/bimg"
)

var Extensions = []string{".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".gif", ".heic", ".avif"}

func orDefault(value string, def string) string {
	if value == "" {
		return def
	}
	return value
}

func envInt(key string, def int) int {
	if v := os.Getenv(key); v != "" {
		var n int
		if _, err := fmt.Sscanf(v, "%d", &n); err == nil {
			return n
		}
	}
	return def
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

func listGithubCandidates(gh githubSource, filter string) ([]string, error) {
	url := fmt.Sprintf("https://api.github.com/repos/%s/%s/git/trees/HEAD?recursive=1", gh.owner, gh.repo)
	resp, err := githubRequest(url)
	if err != nil {
		return nil, fmt.Errorf("query GitHub API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GitHub API returned status %d", resp.StatusCode)
	}

	var tree treeResponse
	if err := json.NewDecoder(resp.Body).Decode(&tree); err != nil {
		return nil, fmt.Errorf("parse GitHub API response: %w", err)
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
	return candidates, nil
}

type lfsPointer struct {
	OID  string
	Size int64
}

func parseLFSPointer(data []byte) (*lfsPointer, bool) {
	const magic = "version https://git-lfs.github.com/spec/v1"
	s := strings.TrimSpace(string(data))
	if !strings.HasPrefix(s, magic) {
		return nil, false
	}
	p := &lfsPointer{}
	for _, line := range strings.Split(s, "\n") {
		if after, ok := strings.CutPrefix(line, "oid sha256:"); ok {
			p.OID = strings.TrimSpace(after)
		} else if after, ok := strings.CutPrefix(line, "size "); ok {
			fmt.Sscanf(strings.TrimSpace(after), "%d", &p.Size)
		}
	}
	if p.OID == "" {
		return nil, false
	}
	return p, true
}

func downloadLFSObject(gh githubSource, ptr *lfsPointer, ext string) (string, error) {
	type lfsObj struct {
		OID  string `json:"oid"`
		Size int64  `json:"size"`
	}
	reqBody, _ := json.Marshal(struct {
		Operation string   `json:"operation"`
		Transfers []string `json:"transfers"`
		Objects   []lfsObj `json:"objects"`
	}{
		Operation: "download",
		Transfers: []string{"basic"},
		Objects:   []lfsObj{{OID: ptr.OID, Size: ptr.Size}},
	})

	batchURL := fmt.Sprintf("https://github.com/%s/%s.git/info/lfs/objects/batch", gh.owner, gh.repo)
	req, err := http.NewRequest("POST", batchURL, bytes.NewReader(reqBody))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/vnd.git-lfs+json")
	req.Header.Set("Accept", "application/vnd.git-lfs+json")
	if token := os.Getenv("GITHUB_TOKEN"); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("LFS batch request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("LFS batch returned status %d", resp.StatusCode)
	}

	var batchResp struct {
		Objects []struct {
			Actions struct {
				Download struct {
					Href string `json:"href"`
				} `json:"download"`
			} `json:"actions"`
			Error *struct {
				Message string `json:"message"`
			} `json:"error"`
		} `json:"objects"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&batchResp); err != nil {
		return "", fmt.Errorf("decode LFS batch response: %w", err)
	}
	if len(batchResp.Objects) == 0 {
		return "", fmt.Errorf("LFS batch returned no objects")
	}
	obj := batchResp.Objects[0]
	if obj.Error != nil {
		return "", fmt.Errorf("LFS error: %s", obj.Error.Message)
	}

	dlResp, err := http.Get(obj.Actions.Download.Href)
	if err != nil {
		return "", fmt.Errorf("LFS download: %w", err)
	}
	defer dlResp.Body.Close()

	if dlResp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("LFS download returned status %d", dlResp.StatusCode)
	}

	tmp, err := os.CreateTemp("", "wallpaper-*"+ext)
	if err != nil {
		return "", fmt.Errorf("create temp file: %w", err)
	}
	defer tmp.Close()

	if _, err := io.Copy(tmp, dlResp.Body); err != nil {
		os.Remove(tmp.Name())
		return "", fmt.Errorf("write temp file: %w", err)
	}
	return tmp.Name(), nil
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

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read response: %w", err)
	}

	// Detect Git LFS pointer files and fetch the real object via the batch API.
	if ptr, ok := parseLFSPointer(body); ok {
		return downloadLFSObject(gh, ptr, filepath.Ext(filePath))
	}

	ext := filepath.Ext(filePath)
	tmp, err := os.CreateTemp("", "wallpaper-*"+ext)
	if err != nil {
		return "", fmt.Errorf("create temp file: %w", err)
	}
	defer tmp.Close()

	if _, err := tmp.Write(body); err != nil {
		os.Remove(tmp.Name())
		return "", fmt.Errorf("write temp file: %w", err)
	}
	return tmp.Name(), nil
}

func applyWallpaper(de, filePath string) error {
	switch de {
	case "auto":
		if _, err := exec.LookPath("noctalia-shell"); err == nil {
			return runNoctalia(filePath)
		}
		return fmt.Errorf("could not auto-detect a supported desktop environment")
	case "noctalia":
		return runNoctalia(filePath)
	default:
		return fmt.Errorf("unknown desktop environment: %s", de)
	}
}

func runNoctalia(filePath string) error {
	cmd := exec.Command("noctalia-shell", "ipc", "call", "wallpaper", "set", filePath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func readFilterFile(p string) string {
	data, err := os.ReadFile(p)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

// changeWallpaper picks, converts and applies one wallpaper. Errors are
// returned instead of fatal: in --daemon mode a transient failure (no
// network, GitHub 5xx) must not kill the long-running process.
func changeWallpaper(isGithub bool, gh githubSource, localPath, filter, output, apply string, number int) (string, error) {
	candidates, err := listCandidates(isGithub, gh, localPath, filter)
	if err != nil {
		return "", err
	}

	if len(candidates) == 0 {
		return "", fmt.Errorf("couldn't find any wallpaper, please ensure that your filter is valid")
	}

	n := number
	if n == -1 {
		n = rand.Int()
	}
	picked := candidates[n%len(candidates)]

	var srcPath string
	isTmp := false

	if isGithub {
		tmp, err := downloadGithubImage(gh, picked)
		if err != nil {
			return "", fmt.Errorf("download wallpaper: %w", err)
		}
		srcPath = tmp
		isTmp = true
	} else {
		srcPath = picked
	}

	finalPath := srcPath
	if output != "" {
		// Noctalia's WallpaperService compares PATHS, not file contents, and
		// returns early when the new path equals the current one. Writing to a
		// fixed --output would therefore apply once and then silently no-op
		// forever. Write a uniquely named sibling instead, and prune the old
		// ones so the directory does not grow without bound.
		target := uniqueOutputPath(output)
		if err := convertImage(srcPath, target); err != nil {
			if isTmp {
				os.Remove(srcPath)
			}
			return "", fmt.Errorf("convert wallpaper: %w", err)
		}
		if isTmp {
			os.Remove(srcPath)
			isTmp = false
		}
		finalPath = target
	}

	if apply != "" {
		if err := applyWallpaper(apply, finalPath); err != nil {
			return "", fmt.Errorf("apply wallpaper: %w", err)
		}
		if isTmp {
			os.Remove(finalPath)
		}
		if output != "" {
			// Only prune after a successful apply: the file in use must stay.
			pruneOldOutputs(output, finalPath)
		}
	} else {
		fmt.Printf("%s", finalPath)
	}
	return picked, nil
}

// uniqueOutputPath turns ".../current.png" into ".../current-<nanos>.png" so
// every change produces a path noctalia has not seen before.
func uniqueOutputPath(output string) string {
	ext := filepath.Ext(output)
	base := strings.TrimSuffix(output, ext)
	return fmt.Sprintf("%s-%d%s", base, time.Now().UnixNano(), ext)
}

// pruneOldOutputs deletes previously generated "<base>-*<ext>" files, keeping
// only keep (the one just applied). Failures are ignored: a leftover file is
// harmless compared with aborting a successful change.
func pruneOldOutputs(output, keep string) {
	ext := filepath.Ext(output)
	base := strings.TrimSuffix(output, ext)
	matches, err := filepath.Glob(base + "-*" + ext)
	if err != nil {
		return
	}
	for _, m := range matches {
		if m != keep {
			os.Remove(m)
		}
	}
}

// listCandidates returns every selectable image path of the configured
// source, restricted to filter.
func listCandidates(isGithub bool, gh githubSource, localPath, filter string) ([]string, error) {
	if isGithub {
		return listGithubCandidates(gh, filter)
	}
	return list_candidates(path.Join(localPath, filter))
}

// listCollections returns the sorted set of directories that actually hold
// images, relative to the source root: exactly the values accepted as a
// filter. Used by the noctalia panel to offer a pick list.
func listCollections(isGithub bool, gh githubSource, localPath string) ([]string, error) {
	candidates, err := listCandidates(isGithub, gh, localPath, "")
	if err != nil {
		return nil, err
	}
	seen := map[string]bool{}
	var out []string
	for _, c := range candidates {
		if !isGithub {
			rel, err := filepath.Rel(localPath, c)
			if err != nil {
				continue
			}
			c = rel
		}
		dir := filepath.Dir(c)
		if dir == "." || dir == "/" || seen[dir] {
			continue
		}
		seen[dir] = true
		out = append(out, dir)
	}
	slices.Sort(out)
	return out, nil
}

func envDuration(key string, def time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return def
}

func resolveFilter(filterFlag, filterFile string) string {
	if filterFile != "" {
		return readFilterFile(filterFile)
	}
	return filterFlag
}

// daemonState holds the mutable, socket-controllable state of a running
// `--daemon` instance: the current filter and a channel to force an
// immediate wallpaper change (used by the "trigger" socket command).
type daemonState struct {
	mu      sync.Mutex
	filter  string
	current string
	// trigger carries a reply channel: the main loop sends back the change's
	// error (nil on success) so a socket client learns whether it worked
	// instead of getting an unconditional ok.
	trigger chan chan error
	// listFn lists the selectable collections of the configured source.
	listFn func() ([]string, error)
}

func (s *daemonState) getFilter() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.filter
}

func (s *daemonState) setFilter(f string) {
	s.mu.Lock()
	s.filter = f
	s.mu.Unlock()
}

func (s *daemonState) getCurrent() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.current
}

func (s *daemonState) setCurrent(p string) {
	s.mu.Lock()
	s.current = p
	s.mu.Unlock()
}

// socketRequest/socketResponse are the JSON line protocol spoken over the
// daemon's control socket. One JSON object per line in, one JSON object per
// line out.
type socketRequest struct {
	Cmd   string `json:"cmd"`
	Value string `json:"value,omitempty"`
}

type socketResponse struct {
	Ok          bool     `json:"ok"`
	Error       string   `json:"error,omitempty"`
	Filter      string   `json:"filter,omitempty"`
	Current     string   `json:"current,omitempty"`
	Collections []string `json:"collections,omitempty"`
}

// serveSocket listens on a Unix socket and handles "trigger", "get_filter",
// and "set_filter" commands against state, one JSON request/response per
// line. Runs until the listener errors (e.g. socket removed).
func serveSocket(socketPath string, state *daemonState) {
	os.Remove(socketPath)
	ln, err := net.Listen("unix", socketPath)
	if err != nil {
		log.Printf("Failed to listen on socket %s: %v", socketPath, err)
		return
	}
	defer ln.Close()

	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Printf("Socket accept error: %v", err)
			return
		}
		go handleSocketConn(conn, state)
	}
}

// defaultSocketPath is where the daemon listens unless overridden (matches
// the niri module's wallpaperSocket).
func defaultSocketPath() string {
	dir := os.Getenv("XDG_RUNTIME_DIR")
	if dir == "" {
		dir = os.TempDir()
	}
	return filepath.Join(dir, "change-wallpaper.sock")
}

// sendMsg connects to the daemon's control socket, writes one JSON line,
// prints the one-line JSON reply, and returns the process exit code.
func sendMsg(socketPath, msg string) int {
	if !json.Valid([]byte(msg)) {
		log.Fatalf("--msg is not valid JSON: %s", msg)
	}
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		log.Fatalf("Failed to connect to daemon socket %s: %v", socketPath, err)
	}
	defer conn.Close()

	if _, err := fmt.Fprintln(conn, msg); err != nil {
		log.Fatalf("Failed to send message: %v", err)
	}

	scanner := bufio.NewScanner(conn)
	if !scanner.Scan() {
		log.Fatalf("No response from daemon: %v", scanner.Err())
	}
	fmt.Println(scanner.Text())

	var resp socketResponse
	if err := json.Unmarshal(scanner.Bytes(), &resp); err == nil && !resp.Ok {
		return 1
	}
	return 0
}

func handleSocketConn(conn net.Conn, state *daemonState) {
	defer conn.Close()
	scanner := bufio.NewScanner(conn)
	enc := json.NewEncoder(conn)

	for scanner.Scan() {
		var req socketRequest
		resp := socketResponse{Ok: true}
		if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
			resp = socketResponse{Ok: false, Error: "invalid JSON: " + err.Error()}
			enc.Encode(resp)
			continue
		}

		switch req.Cmd {
		case "trigger":
			// Wait for the change to finish so the caller (bar widget) can
			// show a real success/failure instead of fire-and-forget.
			reply := make(chan error, 1)
			select {
			case state.trigger <- reply:
				if err := <-reply; err != nil {
					resp = socketResponse{Ok: false, Error: err.Error()}
				} else {
					resp.Current = state.getCurrent()
				}
			default:
				resp = socketResponse{Ok: false, Error: "a change is already in progress"}
			}
		case "status":
			resp.Filter = state.getFilter()
			resp.Current = state.getCurrent()
		case "get_filter":
			resp.Filter = state.getFilter()
		case "set_filter":
			state.setFilter(req.Value)
			resp.Filter = req.Value
		case "list_collections":
			cols, err := state.listFn()
			if err != nil {
				resp = socketResponse{Ok: false, Error: err.Error()}
			} else {
				resp.Collections = cols
				resp.Filter = state.getFilter()
			}
		default:
			resp = socketResponse{Ok: false, Error: "unknown command: " + req.Cmd}
		}

		enc.Encode(resp)
	}
}

func main() {
	rootDir := flag.String("root-dir", orDefault(os.Getenv("WALLPAPER_ROOT"), "."), "Path to the wallpaper repository, or github:owner/repo")
	filter := flag.String("filter", os.Getenv("WALLPAPER_FILTER"), "Select specific wallpaper collections (e.g. \"digital-art/cosmic-journeys\")")
	filterFile := flag.String("filter-file", os.Getenv("WALLPAPER_FILTER_FILE"), "File whose contents are used as the filter (re-read each tick in daemon mode)")
	number := flag.Int("number", envInt("WALLPAPER_NUMBER", -1), "If set, selects the n-th file, otherwise defaults to random.")
	output := flag.String("output", os.Getenv("WALLPAPER_OUTPUT"), "Path where the wallpaper should be saved (supported formats: png, jpg, jpeg, gif)")
	apply := flag.String("apply", os.Getenv("WALLPAPER_APPLY"), "Apply the wallpaper to the desktop: \"noctalia\" or \"auto\" to detect")
	daemon := flag.Bool("daemon", false, "Run continuously, changing the wallpaper at each interval")
	interval := flag.Duration("interval", envDuration("WALLPAPER_INTERVAL", 30*time.Minute), "Time between wallpaper changes in daemon mode (e.g. 30m, 1h)")
	retryInterval := flag.Duration("retry-interval", envDuration("WALLPAPER_RETRY_INTERVAL", 30*time.Second), "How soon to retry in daemon mode after a failed change (e.g. no network at login)")
	socketPath := flag.String("socket", os.Getenv("WALLPAPER_SOCKET"), "Path to the daemon's Unix control socket. Defaults to $XDG_RUNTIME_DIR/change-wallpaper.sock (used both to serve it in --daemon mode and to reach it with --msg)")
	msg := flag.String("msg", "", "Send one JSON line (e.g. '{\"cmd\":\"trigger\"}') to a running --daemon's control socket, print the reply, and exit; does not pick/apply a wallpaper itself")

	flag.Parse()

	if *socketPath == "" {
		*socketPath = defaultSocketPath()
	}

	if *msg != "" {
		os.Exit(sendMsg(*socketPath, *msg))
	}

	isGithub, gh, localPath := parseSource(*rootDir)
	initialFilter := resolveFilter(*filter, *filterFile)

	if !*daemon {
		if _, err := changeWallpaper(isGithub, gh, localPath, initialFilter, *output, *apply, *number); err != nil {
			log.Fatalf("Failed to change wallpaper: %v", err)
		}
		return
	}

	state := &daemonState{filter: initialFilter, trigger: make(chan chan error, 1)}
	// change runs one wallpaper change with the filter currently in effect.
	// A filter set via the socket takes priority; otherwise fall back to the
	// flag/file-based filter, re-read on every change.
	// ponytail: empty filter is ambiguous between "unset" and "explicitly
	// cleared via socket"; falls back to flag/file. Add a tri-state if
	// that distinction ever matters.
	state.listFn = func() ([]string, error) {
		return listCollections(isGithub, gh, localPath)
	}
	change := func() error {
		f := state.getFilter()
		if f == "" {
			f = resolveFilter(*filter, *filterFile)
		}
		picked, err := changeWallpaper(isGithub, gh, localPath, f, *output, *apply, *number)
		if err == nil {
			state.setCurrent(picked)
		}
		return err
	}

	if *socketPath != "" {
		go serveSocket(*socketPath, state)
	}

	ticker := time.NewTicker(*interval)
	defer ticker.Stop()
	// After a failure, retry well before the next regular tick: the usual
	// cause is a transient one (no network yet at login, compositor not
	// ready for the IPC call), which clears in seconds, not in --interval.
	if err := change(); err != nil {
		log.Printf("Failed to change wallpaper: %v", err)
		ticker.Reset(*retryInterval)
	}

	for {
		var reply chan error
		select {
		case <-ticker.C:
		case reply = <-state.trigger:
		}
		err := change()
		if err != nil {
			log.Printf("Failed to change wallpaper: %v", err)
			ticker.Reset(*retryInterval)
		} else {
			ticker.Reset(*interval)
		}
		if reply != nil {
			reply <- err
		}
	}
}

func list_candidates(root_dir string) ([]string, error) {
	candidates := []string{}

	err := filepath.WalkDir(root_dir, func(path string, d fs.DirEntry, err error) error {
		if d != nil && !d.IsDir() && slices.Contains(Extensions, filepath.Ext(d.Name())) {
			candidates = append(candidates, path)
		}

		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("list wallpapers in %s: %w", root_dir, err)
	}

	return candidates, nil
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
