{ pkgs }:
let
  system = pkgs.stdenv.hostPlatform.system;
  nixt = builtins.getFlake "github:kalitsune/nixt";
  pie = builtins.getFlake "github:epita/nixpie";
  nixtPkgs = nixt.packages.${system};
  terminal = pie.inputs.nixpkgs.legacyPackages.${system}.alacritty;

  # EPITA machines are a single 1920x1080 DP-1 screen: only the lockscreen widget
  # placement differs from the base nixt noctalia (widgets themselves live in
  # modules/features/noctalia/noctalia.nix).
  noctalia = nixtPkgs.noctalia.wrap {
    settings.lockscreen_widgets = {
      widget_order = [
        "clock_analog"
        "clock_digital"
        "login"
      ];
      grid = {
        cell_size = 16;
        major_interval = 4;
        visible = true;
      };
      widget = {
        clock_analog = {
          output = "DP-1";
          placement_width = 1920.0;
          placement_height = 1080.0;
          cx = 655.0;
          cy = 620.0;
          rotation = 0.0;
        };
        clock_digital = {
          output = "DP-1";
          placement_width = 1920.0;
          placement_height = 1080.0;
          cx = 1071.5;
          cy = 620.0;
          rotation = 0.0;
        };
        login = {
          output = "DP-1";
          placement_width = 1920.0;
          placement_height = 1080.0;
          box_width = 810.0;
          box_height = 196.0;
          cx = 960.0;
          cy = 898.0;
          rotation = 0.0;
        };
      };
    };
  };

  keybinds = import ./features/keybinds.nix {
    nixtPkgs = nixtPkgs // {
      inherit noctalia;
    };
    inherit terminal;
  };

  # Build a shell-command string from a keybind action attrset.
  cmd = kb: builtins.concatStringsSep " " ([ (pkgs.lib.getExe kb.package) ] ++ (kb.args or [ ]));

  basePackages = nixtPkgs // {
    inherit terminal noctalia;
  };
in
{
  inherit
    system
    nixt
    pie
    terminal
    noctalia
    keybinds
    ;

  # Per-DE config builders. Each takes an optional attrset of keybind overrides
  # (recursively merged with keybinds.nix) and returns a desktop package.
  desktops = {
    niri =
      extra:
      let
        kb = pkgs.lib.recursiveUpdate keybinds extra;
        epitaBinds = {
          "${kb.terminal.key}".spawn-sh = cmd kb.terminal;
          "${kb.launcher.key}".spawn-sh = cmd kb.launcher;
          "${kb.sessionMenu.key}".spawn-sh = cmd kb.sessionMenu;
          "${kb.closeWindow.key}".close-window = _: { };
        };
        extraUnbinds = pkgs.lib.flatten (pkgs.lib.mapAttrsToList (_: action: action.unbind or [ ]) kb);
        mergedBinds =
          (pkgs.lib.filterAttrs (
            k: _: !(epitaBinds ? ${k}) && !(builtins.elem k extraUnbinds)
          ) nixtPkgs.niri.configuration.settings.binds)
          // epitaBinds;
        noctalia_bin = "${noctalia}/bin";
        changeWp = pkgs.lib.getExe nixtPkgs.change-wallpaper;
        # Strip the wallpaper-daemon inherited from an older base niri package, and
        # the base noctalia so the DP-1-positioned wrapper above is spawned instead.
        filteredSpawnAt = pkgs.lib.filter (
          x:
          !(
            builtins.isString x
            && (pkgs.lib.hasSuffix "wallpaper-daemon" x || pkgs.lib.hasInfix "/bin/noctalia" x)
          )
        ) nixtPkgs.niri.configuration.settings.spawn-at-startup;
      in
      nixtPkgs.niri.wrap {
        settings = {
          spawn-at-startup = pkgs.lib.mkForce (filteredSpawnAt ++ [ (pkgs.lib.getExe noctalia) ]);
          spawn-sh-at-startup = [
            "${pkgs.xorg.xrdb}/bin/xrdb -merge \"$HOME/.Xresources\" 2>/dev/null || true"
            # Wait 3 s for noctalia to finish init before the first IPC wallpaper call.
            "sleep 3; export PATH=\"${noctalia_bin}:$PATH\"; exec ${changeWp} --filter-file=\"$HOME/.config/wallpaper-filter.txt\" --apply=noctalia --daemon"
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
