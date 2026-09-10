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
        mergedBinds =
          (pkgs.lib.filterAttrs (k: _: !(epitaBinds ? ${k}))
            nixtPkgs.niri.configuration.settings.binds)
          // epitaBinds;
      in
      nixtPkgs.niri.wrap {
        settings.binds = pkgs.lib.mkForce mergedBinds;
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
