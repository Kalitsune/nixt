# Niri settings for the EPITA pie desktop.
# Each bind is a single-action attrset; use // at the bind level to replace
# an entire binding without sub-attribute merging.
{ pkgs, nixtPkgs, terminal }:
let
  noctalia = pkgs.lib.getExe nixtPkgs.noctalia-shell;
  vicinae  = pkgs.lib.getExe nixtPkgs.vicinae;
in
{
  binds = {
    "Mod+Return".spawn-sh  = pkgs.lib.getExe terminal;
    "Mod+Shift+E".spawn-sh = "${noctalia} ipc call sessionMenu toggle";
    "Mod+Shift+Q".close-window = _: { };
    "Mod+D".spawn-sh       = "${vicinae} toggle";
  };
}
