# Wallpaper
This nix package is a wrapper for my [wallpaper repo](https://github.com/Kalitsune/wallpapers).
It includes all of my wallpapers in a nice little package as well as an utility to randomly select wallpapers.

## Usage

```
change-wallpaper [flags]
```

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--root-dir` | `$WALLPAPER_ROOT` or `.` | Path to the wallpaper repository, or `github:owner/repo` to pull directly from GitHub |
| `--filter` | `$WALLPAPER_FILTER` | Restrict selection to a specific collection (e.g. `digital-art/cosmic-journeys`) |
| `--number` | `$WALLPAPER_NUMBER` or _(random)_ | Select the n-th wallpaper instead of a random one |
| `--output` | `$WALLPAPER_OUTPUT` | Write the wallpaper to this path, converting format if needed |

### Environment variables

| Variable | Description |
|----------|-------------|
| `WALLPAPER_ROOT` | Default value for `--root-dir` (accepts both local paths and `github:owner/repo`) |
| `WALLPAPER_FILTER` | Default value for `--filter` |
| `WALLPAPER_NUMBER` | Default value for `--number` (integer) |
| `WALLPAPER_OUTPUT` | Default value for `--output` |
| `GITHUB_TOKEN` | Optional GitHub personal access token — set to avoid rate limits when using a GitHub source |

### Supported input formats

`png`, `jpg`, `jpeg`, `webp`, `bmp`, `tiff`, `gif`, `heic`, `avif`

### Supported output formats

`png`, `jpg`/`jpeg`, `gif`

## Examples

Print the path to a random wallpaper:
```sh
$ change-wallpaper
```

Convert and save a random wallpaper:
```sh
$ change-wallpaper --output ~/.config/wallpaper.png
```

Restrict to a specific collection:
```sh
$ change-wallpaper --filter "digital-art/cosmic-journeys" --output ~/.config/wallpaper.png
```

Pick a deterministic wallpaper (e.g. for a daily wallpaper keyed on the date):
```sh
$ change-wallpaper --number 42 --output ~/.config/wallpaper.png
```

Use a custom wallpaper root via environment variable:
```sh
$ WALLPAPER_ROOT=/path/to/wallpapers change-wallpaper
```

Pull wallpapers directly from a GitHub repository:
```sh
$ change-wallpaper --root-dir github:kalitsune/wallpapers --output ~/.config/wallpaper.png
```

Use a GitHub source with a filter and avoid rate limits with a token:
```sh
$ GITHUB_TOKEN=ghp_... change-wallpaper --root-dir github:kalitsune/wallpapers --filter "digital-art/cosmic-journeys" --output ~/.config/wallpaper.png
```
