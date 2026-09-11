# Global keybind settings for EPITA desktops.
# Imported by nixt-pie.nix; each entry in `desktops` parses this into its own config format.
#
# Per-action options:
#   key     — keybind string, e.g. "Mod+Return" or "Mod+Shift+Q"
#   package — derivation to run; must have a main program (used with lib.getExe)
#   args    — list of extra arguments passed after the binary  (optional, default [])
#   unbind  — list of base niri keys to remove (same action, different key)
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
    unbind  = [ "Mod+T" ];
  };
  launcher = {
    package = nixtPkgs.vicinae;
    args    = [ "toggle" ];
    key     = "Mod+D";
    unbind  = [ "Mod+Space" ];
  };
  sessionMenu = {
    package = nixtPkgs.noctalia-shell;
    args    = [ "ipc" "call" "sessionMenu" "toggle" ];
    key     = "Mod+Shift+E";
    unbind  = [ "Mod+M" ];
  };
  closeWindow = {
    key    = "Mod+Shift+Q";
    unbind = [ "Mod+X" "Mod+Shift+X" ];
  };
}
