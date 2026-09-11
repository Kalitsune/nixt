{ pkgs }:
let
  system   = pkgs.stdenv.hostPlatform.system;
  nixt     = builtins.getFlake "github:kalitsune/nixt";
  pie      = builtins.getFlake "github:epita/nixpie";
  nixtPkgs = nixt.packages.${system};
  terminal = pie.inputs.nixpkgs.legacyPackages.${system}.rxvt-unicode;
  keybinds = import ./features/keybinds.nix { inherit nixtPkgs terminal; };

  # Build a shell-command string from a keybind action attrset.
  cmd = kb: builtins.concatStringsSep " "
    ([ (pkgs.lib.getExe kb.package) ] ++ (kb.args or []));

  basePackages = nixtPkgs // { inherit terminal; };
in
{
  inherit system nixt pie terminal keybinds;

  # Per-DE config builders. Each takes an optional attrset of keybind overrides
  # (recursively merged with keybinds.nix) and returns a desktop package.
  desktops = {
    niri = extra:
      let
        kb = pkgs.lib.recursiveUpdate keybinds extra;
        epitaBinds = {
          "${kb.terminal.key}".spawn-sh    = cmd kb.terminal;
          "${kb.launcher.key}".spawn-sh    = cmd kb.launcher;
          "${kb.sessionMenu.key}".spawn-sh = cmd kb.sessionMenu;
          "${kb.closeWindow.key}".close-window = _: { };
        };
        extraUnbinds = pkgs.lib.flatten (
          pkgs.lib.mapAttrsToList (_: action: action.unbind or []) kb
        );
        mergedBinds =
          (pkgs.lib.filterAttrs
            (k: _: !(epitaBinds ? ${k}) && !(builtins.elem k extraUnbinds))
            nixtPkgs.niri.configuration.settings.binds)
          // epitaBinds;
      in
      nixtPkgs.niri.wrap {
        settings = {
          # Load the user's ~/.Xresources so urxvt picks up their font/colors.
          # xwayland-satellite handles the DISPLAY socket, so xrdb can connect
          # at startup without needing Xwayland to be pre-running.
          spawn-sh-at-startup = [
            "${pkgs.xorg.xrdb}/bin/xrdb -merge \"$HOME/.Xresources\" 2>/dev/null || true"
          ];
          binds = pkgs.lib.mkForce mergedBinds;
        };
      };
  };

  mkLauncher =
    name: extraPackages:
    let
      packages = basePackages // extraPackages;
    in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        packages.terminal
        packages.editor
      ];
      text = ''
        export SHELL=${pkgs.lib.getExe packages.shell}
        exec ${pkgs.lib.getExe packages.desktop}
      '';
    };
}
