package main

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

// The regression these cover: every failure path used to be log.Fatal, which
// killed a running --daemon on the first network blip and froze the wallpaper
// until the compositor was restarted. They must return errors instead.

func writePNG(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	// 1x1 red PNG.
	data := []byte{
		0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a,
		0, 0, 0, 0x0d, 'I', 'H', 'D', 'R', 0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 0x90, 0x77, 0x53, 0xde,
		0, 0, 0, 0x0c, 'I', 'D', 'A', 'T', 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00, 0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d, 0xb0,
		0, 0, 0, 0, 'I', 'E', 'N', 'D', 0xae, 0x42, 0x60, 0x82,
	}
	if err := os.WriteFile(path, data, 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestListCollections(t *testing.T) {
	root := t.TempDir()
	writePNG(t, filepath.Join(root, "nature", "forest", "a.png"))
	writePNG(t, filepath.Join(root, "abstract", "b.png"))
	// A stray non-image must not create a collection.
	if err := os.WriteFile(filepath.Join(root, "notes.txt"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}

	got, err := listCollections(false, githubSource{}, root)
	if err != nil {
		t.Fatalf("listCollections: %v", err)
	}
	want := []string{"abstract", "nature/forest"}
	if !slices.Equal(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestChangeWallpaperBadFilterReturnsError(t *testing.T) {
	root := t.TempDir()
	writePNG(t, filepath.Join(root, "abstract", "b.png"))

	// Must return an error (not exit the process) so the daemon loop survives.
	if _, err := changeWallpaper(false, githubSource{}, root, "does-not-exist", "", "", -1); err == nil {
		t.Fatal("expected an error for a filter matching no wallpaper")
	}
}

func TestChangeWallpaperReturnsPicked(t *testing.T) {
	root := t.TempDir()
	writePNG(t, filepath.Join(root, "abstract", "b.png"))
	outDir := t.TempDir()
	out := filepath.Join(outDir, "current.png")

	picked, err := changeWallpaper(false, githubSource{}, root, "abstract", out, "", -1)
	if err != nil {
		t.Fatalf("changeWallpaper: %v", err)
	}
	if picked != filepath.Join(root, "abstract", "b.png") {
		t.Fatalf("unexpected pick: %s", picked)
	}
	// The written file is a uniquely named sibling of --output, never
	// --output itself (see uniqueOutputPath).
	written, err := filepath.Glob(filepath.Join(outDir, "current-*.png"))
	if err != nil || len(written) != 1 {
		t.Fatalf("expected exactly one generated file, got %v (err %v)", written, err)
	}
}

// Regression: noctalia's WallpaperService returns early when the new path
// equals the current one, so two consecutive changes must not reuse a path or
// the wallpaper visibly stops updating.
func TestConsecutiveChangesUseDistinctPaths(t *testing.T) {
	root := t.TempDir()
	writePNG(t, filepath.Join(root, "abstract", "b.png"))
	outDir := t.TempDir()
	out := filepath.Join(outDir, "current.png")

	var seen []string
	for i := 0; i < 2; i++ {
		if _, err := changeWallpaper(false, githubSource{}, root, "abstract", out, "", -1); err != nil {
			t.Fatalf("changeWallpaper #%d: %v", i, err)
		}
		got, _ := filepath.Glob(filepath.Join(outDir, "current-*.png"))
		if len(got) == 0 {
			t.Fatalf("no output written on pass %d", i)
		}
		seen = append(seen, got[len(got)-1])
	}
	if seen[0] == seen[1] {
		t.Fatalf("both changes wrote the same path %s; noctalia would skip the second", seen[0])
	}
}

func TestPruneOldOutputsKeepsOnlyCurrent(t *testing.T) {
	outDir := t.TempDir()
	out := filepath.Join(outDir, "current.png")
	keep := filepath.Join(outDir, "current-222.png")
	for _, f := range []string{filepath.Join(outDir, "current-111.png"), keep} {
		writePNG(t, f)
	}
	// An unrelated file must survive the prune.
	other := filepath.Join(outDir, "unrelated.png")
	writePNG(t, other)

	pruneOldOutputs(out, keep)

	if _, err := os.Stat(keep); err != nil {
		t.Fatalf("current output was pruned: %v", err)
	}
	if _, err := os.Stat(filepath.Join(outDir, "current-111.png")); !os.IsNotExist(err) {
		t.Fatal("stale output was not pruned")
	}
	if _, err := os.Stat(other); err != nil {
		t.Fatalf("unrelated file was pruned: %v", err)
	}
}
