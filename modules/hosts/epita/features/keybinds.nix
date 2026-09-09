# Global keybind settings for EPITA desktops.
# Imported by nixt-pie.nix; each entry in `desktops` parses this into its own config format.
#
# Per-action options:
#   key     — keybind string, e.g. "Mod+Return" or "Mod+Shift+Q"
#   package — derivation to run; must have a main program (used with lib.getExe)
#   args    — list of extra arguments passed after the binary  (optional, default [])
#
# Recognised actions:
#   terminal    — spawn the terminal emulator
#   launcher    — open the app launcher
#   sessionMenu — open the power / session menu
#   closeWindow — close the focused window  (DE-native action, no package)
{ nixtPkgs, terminal }:
{
  terminal = {
    package = terminal;
    key     = "Mod+Return";
  };
  launcher = {
    package = nixtPkgs.vicinae;
    args    = [ "toggle" ];
    key     = "Mod+D";
  };
  sessionMenu = {
    package = nixtPkgs.noctalia-shell;
    args    = [ "ipc" "call" "sessionMenu" "toggle" ];
    key     = "Mod+Shift+E";
  };
  closeWindow = {
    key = "Mod+Shift+Q";
  };
}
