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
| `--socket` | `$WALLPAPER_SOCKET` or `$XDG_RUNTIME_DIR/change-wallpaper.sock` | In `--daemon` mode, path to the Unix control socket. Also used by `--msg` to reach a running daemon. |
| `--msg` | | Send one JSON line to a running `--daemon`'s control socket (auto-detected at the default socket path unless `--socket`/`WALLPAPER_SOCKET` is set), print the reply, and exit. Does not pick or apply a wallpaper itself. |

### Environment variables

| Variable | Description |
|----------|-------------|
| `WALLPAPER_ROOT` | Default value for `--root-dir` (accepts both local paths and `github:owner/repo`) |
| `WALLPAPER_FILTER` | Default value for `--filter` |
| `WALLPAPER_NUMBER` | Default value for `--number` (integer) |
| `WALLPAPER_FILTER_FILE` | Default value for `--filter-file` (re-read each tick in daemon mode) |
| `WALLPAPER_OUTPUT` | Default value for `--output` |
| `WALLPAPER_APPLY` | Default value for `--apply` |
| `WALLPAPER_INTERVAL` | Default value for `--interval` |
| `WALLPAPER_SOCKET` | Default value for `--socket` |
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

## Daemon control socket

In `--daemon` mode, `--socket <path>` (or `WALLPAPER_SOCKET`) starts a Unix
socket accepting one JSON object per line and replying with one JSON object
per line:

| Command | Request | Response |
|---------|---------|----------|
| Trigger an immediate wallpaper change | `{"cmd":"trigger"}` | `{"ok":true}` |
| Read the current filter | `{"cmd":"get_filter"}` | `{"ok":true,"filter":"..."}` |
| Set the filter (used on the next change, socket wins over `--filter`/`--filter-file`) | `{"cmd":"set_filter","value":"digital-art"}` | `{"ok":true,"filter":"digital-art"}` |

Example:
```sh
$ change-wallpaper --msg '{"cmd":"trigger"}'
```

Auto-detects the running daemon's socket at `$XDG_RUNTIME_DIR/change-wallpaper.sock`
(override with `--socket`/`WALLPAPER_SOCKET`), so no path juggling needed as
long as one `--daemon` instance is running per user. Equivalent raw form:
```sh
$ echo '{"cmd":"trigger"}' | socat - UNIX-CONNECT:$XDG_RUNTIME_DIR/change-wallpaper.sock
```

This is what the `wallpaper-picker` Noctalia plugin (see
`../noctalia-shell/plugins/wallpaper-picker`) uses instead of Noctalia's
built-in wallpaper picker: click the bar widget to trigger a change,
right-click to open a panel that reads/sets the filter.

