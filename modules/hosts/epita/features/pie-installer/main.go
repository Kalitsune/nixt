package main

import (
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"syscall"

	"github.com/charmbracelet/bubbles/paginator"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

const (
	flakeURL      = "github:kalitsune/nixt"
	installerPkg  = "pie-installer"
	confsRelDir   = "afs/.confs"
	installScript = "install.sh"
	commandFile   = "pie-installer-cmd"
	tty2Device    = "/dev/tty2"
)

// ── Styles ────────────────────────────────────────────────────────────────────

var (
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("212"))

	warningStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("3"))

	boxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("3")).
			Padding(1, 2)

	cursorStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("212"))

	optionStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("255"))

	dimStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("240"))

	helpStyle = lipgloss.NewStyle().
			Italic(true).
			Foreground(lipgloss.Color("241"))

	signatureStyle = lipgloss.NewStyle().
			Italic(true).
			Foreground(lipgloss.Color("212"))

	welcomeBoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("212")).
			Padding(1, 2)
)

// ── Config ────────────────────────────────────────────────────────────────────

type config struct {
	style        string
	save         bool
	pick         bool
	dryRun       bool
	styleFromCLI bool
}

func parseArgs() config {
	cfg := config{}
	for _, arg := range os.Args[1:] {
		switch {
		case strings.HasPrefix(arg, "--style="):
			cfg.style = strings.TrimPrefix(arg, "--style=")
			cfg.styleFromCLI = true
		case arg == "--save":
			cfg.save = true
		case arg == "--pick":
			cfg.pick = true
		case arg == "--dry-run":
			cfg.dryRun = true
		case arg == "--help" || arg == "-h":
			printHelp()
			os.Exit(0)
		}
	}
	return cfg
}

func printHelp() {
	fmt.Print(`pie-installer — EPITA Shell Style Installer

USAGE:
  pie-installer [OPTIONS]

OPTIONS:
  --style=nixt|pie   Use this style directly (skips interactive TUI)
  --save             Save chosen style to auto-boot at login
  --pick             Interactive picker without auto-boot prompt
  --dry-run          Print commands that would run without executing them
  --help, -h         Show this help message

EXAMPLES:
  pie-installer                     Interactive: pick style, optionally save
  pie-installer --style=nixt        Use nixt style directly (no TUI)
  pie-installer --style=pie --save  Use pie style and enable auto-boot
  pie-installer --pick              Pick interactively, skip auto-boot prompt
  pie-installer --dry-run           Show what would happen
`)
}

// ── TUI Model ─────────────────────────────────────────────────────────────────

type stepID int

const (
	stepWelcome stepID = iota
	stepStylePicker
	stepAutoboot
	stepDisclaimer
)

type tuiResult struct {
	style        string
	saveAutoboot bool
	aborted      bool
}

type model struct {
	paginator    paginator.Model
	step         stepID
	totalSteps   int
	choice       int
	result       tuiResult
	cfg          config
	hasInstallSh bool
}

func newModel(cfg config) model {
	hasInstallSh := fileExists(installScriptPath())

	// Welcome + picker always shown.
	// --save: welcome → picker → disclaimer (3)
	// --pick or no install.sh: welcome → picker (2)
	// normal + install.sh: welcome → picker → autoboot (3, grows to 4 if user saves)
	var totalSteps int
	switch {
	case cfg.save:
		totalSteps = 3
	case cfg.pick || !hasInstallSh:
		totalSteps = 2
	default:
		totalSteps = 3
	}

	p := paginator.New()
	p.Type = paginator.Dots
	p.TotalPages = totalSteps
	p.ActiveDot = cursorStyle.Render("•")
	p.InactiveDot = dimStyle.Render("○")

	return model{
		paginator:    p,
		totalSteps:   totalSteps,
		cfg:          cfg,
		hasInstallSh: hasInstallSh,
	}
}

func (m model) Init() tea.Cmd { return nil }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch m.step {

		case stepWelcome:
			switch msg.String() {
			case "enter", "y", " ":
				m.step = stepStylePicker
				m.paginator.Page++
				m.choice = 0
			case "n", "q", "esc", "ctrl+c":
				m.result.aborted = true
				return m, tea.Quit
			}

		case stepStylePicker:
			switch msg.String() {
			case "up", "k":
				if m.choice > 0 {
					m.choice--
				}
			case "down", "j":
				if m.choice < 1 {
					m.choice++
				}
			case "enter", " ":
				if m.choice == 0 {
					m.result.style = "nixt"
				} else {
					m.result.style = "pie"
				}
				m.paginator.Page++
				m.choice = 0
				if m.cfg.save {
					m.step = stepDisclaimer
				} else if m.hasInstallSh && !m.cfg.pick {
					m.step = stepAutoboot
				} else {
					return m, tea.Quit
				}
			case "q", "esc", "ctrl+c":
				m.result.aborted = true
				return m, tea.Quit
			}

		case stepAutoboot:
			switch msg.String() {
			case "up", "k":
				if m.choice > 0 {
					m.choice--
				}
			case "down", "j":
				if m.choice < 1 {
					m.choice++
				}
			case "enter", " ":
				if m.choice == 0 {
					// User wants to save — show disclaimer before committing
					m.totalSteps++
					m.paginator.TotalPages++
					m.paginator.Page++
					m.step = stepDisclaimer
					m.choice = 0
				} else {
					return m, tea.Quit
				}
			case "q", "esc", "ctrl+c":
				m.result.aborted = true
				return m, tea.Quit
			}

		case stepDisclaimer:
			switch msg.String() {
			case "enter", "y":
				m.result.saveAutoboot = true
				return m, tea.Quit
			case "n", "q", "esc", "ctrl+c":
				m.result.aborted = true
				return m, tea.Quit
			}
		}
	}
	return m, nil
}

func (m model) View() string {
	if m.result.aborted {
		return ""
	}

	var content string
	switch m.step {
	case stepWelcome:
		content = m.viewWelcome()
	case stepStylePicker:
		content = m.viewStylePicker()
	case stepAutoboot:
		content = m.viewAutoboot()
	case stepDisclaimer:
		content = m.viewDisclaimer()
	default:
		return ""
	}

	return content + "\n\n  " + m.paginator.View() + "\n"
}

func (m model) viewWelcome() string {
	body := titleStyle.Render("pie-installer") + "\n\n" +
		"Configure your EPITA session with a custom shell environment.\n" +
		"This tool will help you pick a style and optionally save it\n" +
		"so it loads automatically at login.\n\n" +
		signatureStyle.Render("I hope you enjoy my config as much as I enjoyed making it <3") + "\n" +
		signatureStyle.Render("                                              — fanny.alacoque") + "\n\n" +
		helpStyle.Render("[enter]  Start     [q]  Exit")
	return welcomeBoxStyle.Render(body)
}

func (m model) viewDisclaimer() string {
	body := warningStyle.Render("DISCLAIMER — Non-Official Software Installation") + "\n\n" +
		"The authors of pie-installer " + warningStyle.Render("DECLINE ALL RESPONSIBILITY") + "\n" +
		"for any damage, data loss, or session issues resulting from its use.\n\n" +
		"Installing non-official programs on EPITA machines is done under\n" +
		warningStyle.Render("YOUR OWN RESPONSIBILITY") + ". By proceeding, you acknowledge:\n\n" +
		warningStyle.Render("  • ") + "This software is NOT officially supported by EPITA or CRI\n" +
		warningStyle.Render("  • ") + "Your session configuration may be permanently altered\n" +
		warningStyle.Render("  • ") + "The authors provide NO warranty, support, or guarantees\n" +
		warningStyle.Render("  • ") + "You alone are responsible for any consequences\n\n" +
		dimStyle.Render("If in doubt, consult EPITA's IT policy or contact CRI.") + "\n\n" +
		helpStyle.Render("[enter / y]  Accept     [n / q]  Decline")
	return boxStyle.Render(body)
}

func (m model) viewStylePicker() string {
	type opt struct{ name, desc string }
	opts := []opt{
		{"Nixt Style", "default nixt desktop environment"},
		{"Pie Style", "EPITA Pie desktop with custom keybindings"},
	}

	var sb strings.Builder
	sb.WriteString(titleStyle.Render("Choose your shell configuration:") + "\n\n")
	for i, o := range opts {
		if i == m.choice {
			sb.WriteString(cursorStyle.Render("▶ ") + optionStyle.Render(o.name))
			sb.WriteString("  " + dimStyle.Render(o.desc))
		} else {
			sb.WriteString("  " + dimStyle.Render(o.name))
		}
		sb.WriteString("\n")
	}
	sb.WriteString("\n" + helpStyle.Render("[↑ / ↓]  Navigate     [enter]  Select     [q]  Exit"))
	return sb.String()
}

func (m model) viewAutoboot() string {
	opts := []string{"Yes, enable auto-boot", "No, keep manual"}

	var sb strings.Builder
	sb.WriteString(titleStyle.Render("Enable auto-boot at login?") + "\n")
	sb.WriteString(dimStyle.Render("Selected style: "+m.result.style) + "\n\n")
	for i, o := range opts {
		if i == m.choice {
			sb.WriteString(cursorStyle.Render("▶ ") + optionStyle.Render(o))
		} else {
			sb.WriteString("  " + dimStyle.Render(o))
		}
		sb.WriteString("\n")
	}
	sb.WriteString("\n" + helpStyle.Render("[↑ / ↓]  Navigate     [enter]  Confirm     [q]  Exit"))
	return sb.String()
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func ttyDevice() string {
	link, err := os.Readlink("/proc/self/fd/0")
	if err == nil {
		return link
	}
	out, err := exec.Command("tty").Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func homeDir() string {
	home, err := os.UserHomeDir()
	if err != nil {
		home = os.Getenv("HOME")
	}
	return home
}

func installScriptPath() string {
	return homeDir() + "/" + confsRelDir + "/" + installScript
}

func commandFilePath() string {
	return homeDir() + "/" + confsRelDir + "/" + commandFile
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func writeAutoboot(style string) {
	cmdFilePath := commandFilePath()
	scriptPath := installScriptPath()
	fullCommand := fmt.Sprintf("nix run %s#%s --style=%s", flakeURL, installerPkg, style)

	if err := os.WriteFile(cmdFilePath, []byte(fullCommand+"\n"), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "pie-installer: failed to write command file: %v\n", err)
		return
	}

	if !fileExists(scriptPath) {
		fmt.Printf("Auto-boot command saved to %s\n", cmdFilePath)
		return
	}

	if err := updateInstallScript(scriptPath, fullCommand); err != nil {
		fmt.Fprintf(os.Stderr, "pie-installer: failed to update %s: %v\n", scriptPath, err)
		return
	}

	fmt.Printf("Auto-boot enabled: %s\n", fullCommand)
}

func updateInstallScript(path, command string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}

	lines := strings.Split(string(data), "\n")
	piePattern := regexp.MustCompile(`nix run.*#pie-installer`)

	replaced := false
	for i, line := range lines {
		if piePattern.MatchString(line) {
			lines[i] = command
			replaced = true
			break
		}
	}

	if !replaced {
		for len(lines) > 0 && lines[len(lines)-1] == "" {
			lines = lines[:len(lines)-1]
		}
		lines = append(lines, command, "")
	}

	return os.WriteFile(path, []byte(strings.Join(lines, "\n")), 0644)
}

func runNixShell(style string) {
	args := []string{"nix", "develop", "--impure",
		fmt.Sprintf("%s#epita-%s", flakeURL, style)}

	nixPath, err := exec.LookPath("nix")
	if err != nil {
		fmt.Fprintf(os.Stderr, "pie-installer: nix not found in PATH\n")
		os.Exit(1)
	}

	if err := syscall.Exec(nixPath, args, os.Environ()); err != nil {
		fmt.Fprintf(os.Stderr, "pie-installer: exec failed: %v\n", err)
		os.Exit(1)
	}
}

func handleDryRun(cfg config) {
	if !cfg.styleFromCLI {
		fmt.Println("[DRY RUN] Would show Bubble Tea TUI:")
		fmt.Println("[DRY RUN]   Page 1: Welcome screen")
		fmt.Println("[DRY RUN]   Page 2: Style picker (Nixt / Pie)")
		switch {
		case cfg.save:
			fmt.Println("[DRY RUN]   Page 3: Disclaimer (saving enabled via --save)")
		case !cfg.pick && fileExists(installScriptPath()):
			fmt.Println("[DRY RUN]   Page 3: Auto-boot prompt")
			fmt.Println("[DRY RUN]   Page 4: Disclaimer (only if user chooses to save)")
		}
	}

	style := cfg.style
	if style == "" {
		style = "nixt"
		fmt.Println("[DRY RUN] No style given — defaulting to 'nixt' for dry-run output")
	}

	switch {
	case cfg.save:
		cmd := fmt.Sprintf("nix run %s#%s --style=%s", flakeURL, installerPkg, style)
		fmt.Printf("[DRY RUN] Would write to %s:\n  %s\n", commandFilePath(), cmd)
		fmt.Printf("[DRY RUN] Would update %s with:\n  %s\n", installScriptPath(), cmd)
	case !cfg.pick && !cfg.styleFromCLI:
		if fileExists(installScriptPath()) {
			fmt.Println("[DRY RUN] Would prompt for auto-boot (depending on user choice)")
		} else {
			fmt.Printf("[DRY RUN] %s not found — would skip auto-boot prompt\n", installScriptPath())
		}
	}

	fmt.Printf("[DRY RUN] Would exec: nix develop --impure %s#epita-%s\n", flakeURL, style)
}

// ── Main ──────────────────────────────────────────────────────────────────────

func main() {
	cfg := parseArgs()

	if ttyDevice() == tty2Device {
		os.Exit(0)
	}

	if cfg.dryRun {
		handleDryRun(cfg)
		return
	}

	// Non-interactive: --style= bypasses TUI entirely
	if cfg.styleFromCLI {
		if cfg.style != "nixt" && cfg.style != "pie" {
			fmt.Fprintf(os.Stderr, "pie-installer: invalid style %q (must be 'nixt' or 'pie')\n", cfg.style)
			os.Exit(1)
		}
		if cfg.save {
			writeAutoboot(cfg.style)
		}
		runNixShell(cfg.style)
		return
	}

	// Interactive: Bubble Tea TUI with paginator
	prog := tea.NewProgram(newModel(cfg), tea.WithAltScreen())
	final, err := prog.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "pie-installer: TUI error: %v\n", err)
		os.Exit(1)
	}

	res := final.(model).result
	if res.aborted {
		fmt.Fprintln(os.Stderr, "Aborted. No changes made.")
		os.Exit(1)
	}

	if res.saveAutoboot || cfg.save {
		writeAutoboot(res.style)
	}

	runNixShell(res.style)
}
