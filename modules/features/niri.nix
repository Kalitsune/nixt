{
  self,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.niri.blurOpacity = lib.mkOption {
      type = lib.types.float;
      default = 0.7;
      description = "Opacity of unfocused translucent/blurred windows (ghostty, brave, obsidian, hermes).";
    };
  };
  config = {
    flake.nixosModules.niri =
      {
        pkgs,
        lib,
        ...
      }:
      {
        programs.niri = {
          enable = true;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
        };
      };
    perSystem =
      {
        pkgs,
        lib,
        self',
        config,
        ...
      }:
      {
        packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
          inherit pkgs;

          settings =
            let
              blurOpacity = config.niri.blurOpacity;
              noctalia_exe = lib.getExe self'.packages.noctalia;
              wpctl_exe = lib.getExe' pkgs.wireplumber "wpctl";
              vicinae = lib.getExe self'.packages.vicinae;
              env = config.environment;
            in
            {
              # The wallpaper daemon is NOT spawned here: spawn-at-startup is
              # unsupervised, so a single crash left the wallpaper frozen until
              # the next login. It runs as a restarted user unit instead, see
              # modules/features/wallpapers/wallpapers.nix.
              spawn-at-startup = [
                noctalia_exe
                [
                  (lib.getExe self'.packages.vicinae)
                  "server"
                ]
              ];

              xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

              input = {
                focus-follows-mouse = _: { };
                keyboard.xkb = {
                  options = "compose:rctrl";
                  layout = "us";
                };
                touchpad = {
                  tap = _: { };
                  natural-scroll = _: { };
                  dwt = _: { };
                };
              };

              layout = {
                gaps = 7;
                # Let the (blurred) wallpaper show through instead of a flat
                # background color behind windows / in the gaps.
                background-color = "transparent";
              };

              # Noctalia's blurred+tinted wallpaper copy shown in the overview backdrop
              # (needs [backdrop] enabled in noctalia config).
              layer-rules = [
                {
                  matches = [ { namespace = "^noctalia-backdrop"; } ];
                  place-within-backdrop = true;
                }

              ];

              # Stronger global blur (defaults: passes=3, offset=3.0). More passes/offset
              # = smoother, heavier blur.
              blur = {
                passes = 5;
                offset = 8.0;
              };

              overview = {
                zoom = 0.5;
              };

              # noctalia settings (see: https://docs.noctalia.dev/v4/getting-started/compositor-settings/niri/)
              window-rules = [
                {
                  geometry-corner-radius = 20;
                  clip-to-geometry = true;
                  draw-border-with-background = false;
                  opacity = 0.75;
                  background-effect = {
                    blur = true;
                    xray = true;
                  };
                }
                # Nautilus: translucent + blurred (GTK4/libadwaita paints an opaque
                # background, so force opacity != 1 or niri's blur never kicks in).
                {
                  matches = [ { app-id = "^org\\.gnome\\.Nautilus$"; } ];
                  background-effect = {
                    blur = true;
                    xray = true;
                  };
                }
                {
                  matches = [ { is-focused = true; } ];
                  opacity = 0.8;
                }
              ];

              debug.honor-xdg-activation-with-invalid-serial = _: { };

              binds = {
                # Dedicated Launchers
                "Mod+T".spawn-sh = lib.getExe self'.packages.terminal;
                "Mod+E".spawn-sh = lib.getExe self'.packages.file-explorer;
                "Mod+Escape".toggle-overview = _: { };
                "Print".screenshot = _: {
                  props.show-pointer = false;
                };

                # Window Controls
                "Mod+X".close-window = _: { };
                # Force-kill focused window's process via niri IPC (mirrors hyprland killactive)
                "Mod+Shift+X".spawn-sh = "kill -9 $(niri msg -j focused-window | ${lib.getExe pkgs.jq} '.pid')";

                # App Launcher, Clipboard history, Emoji Picker, Power Menu.
                "Mod+V".spawn-sh = "${vicinae} vicinae://launch/clipboard/history";
                "Mod+semicolon".spawn-sh = "${vicinae} vicinae://launch/core/search-emojis";

                # Media Controls
                "XF86AudioRaiseVolume" = _: {
                  props.allow-when-locked = true;
                  content.spawn-sh = "${wpctl_exe} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
                };
                "XF86AudioLowerVolume" = _: {
                  props.allow-when-locked = true;
                  content.spawn-sh = "${wpctl_exe} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                };
                "XF86AudioMute" = _: {
                  props.allow-when-locked = true;
                  content.spawn-sh = "${wpctl_exe} set-mute @DEFAULT_AUDIO_SINK@ toggle";
                };
                "XF86AudioMicMute" = _: {
                  props.allow-when-locked = true;
                  content.spawn-sh = "${wpctl_exe} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                };

                # Brightness Controls
                "XF86MonBrightnessUp" = _: {
                  props.allow-when-locked = true;
                  content.spawn-sh = "${lib.getExe pkgs.brightnessctl} s 10%+";
                };
                "XF86MonBrightnessDown" = _: {
                  props.allow-when-locked = true;
                  content.spawn-sh = "${lib.getExe pkgs.brightnessctl} s 10%-";
                };

                # Focus Relative Windows
                "Mod+Up".focus-workspace-up = _: { };
                "Mod+Down".focus-workspace-down = _: { };
                "Mod+Left".focus-column-left = _: { };
                "Mod+Right".focus-column-right = _: { };
                "Mod+K".focus-workspace-up = _: { };
                "Mod+J".focus-workspace-down = _: { };
                "Mod+H".focus-column-left = _: { };
                "Mod+L".focus-column-right = _: { };

                # Move Relative Windows
                "Mod+Shift+Up".move-column-to-workspace-up = _: { };
                "Mod+Shift+Down".move-column-to-workspace-down = _: { };
                "Mod+Shift+Left".move-column-left = _: { };
                "Mod+Shift+Right".move-column-right = _: { };
                "Mod+Shift+K".move-column-to-workspace-up = _: { };
                "Mod+Shift+J".move-column-to-workspace-down = _: { };
                "Mod+Shift+H".move-column-left = _: { };
                "Mod+Shift+L".move-column-right = _: { };

                # Go to workspace #n
                "Mod+1".focus-workspace = 1;
                "Mod+2".focus-workspace = 2;
                "Mod+3".focus-workspace = 3;
                "Mod+4".focus-workspace = 4;
                "Mod+5".focus-workspace = 5;
                "Mod+6".focus-workspace = 6;
                "Mod+7".focus-workspace = 7;
                "Mod+8".focus-workspace = 8;
                "Mod+9".focus-workspace = 9;
                "Mod+0".focus-workspace = 10;

                # Move to workspace #n
                "Mod+Shift+1".move-column-to-workspace = 1;
                "Mod+Shift+2".move-column-to-workspace = 2;
                "Mod+Shift+3".move-column-to-workspace = 3;
                "Mod+Shift+4".move-column-to-workspace = 4;
                "Mod+Shift+5".move-column-to-workspace = 5;
                "Mod+Shift+6".move-column-to-workspace = 6;
                "Mod+Shift+7".move-column-to-workspace = 7;
                "Mod+Shift+8".move-column-to-workspace = 8;
                "Mod+Shift+9".move-column-to-workspace = 9;
                "Mod+Shift+0".move-column-to-workspace = 10;

                # Window sizing
                "Mod+D".maximize-column = _: { };
                "Mod+F".fullscreen-window = _: { };

                # Resize options
                "Mod+Ctrl+Up".set-window-height = "+5%";
                "Mod+Ctrl+Down".set-window-height = "-5%";
                "Mod+Ctrl+Right".set-column-width = "+5%";
                "Mod+Ctrl+Left".set-column-width = "-5%";

                "Mod+Ctrl+K".set-window-height = "+5%";
                "Mod+Ctrl+J".set-window-height = "-5%";
                "Mod+Ctrl+L".set-column-width = "+5%";
                "Mod+Ctrl+H".set-column-width = "-5%";
              }
              // lib.optionalAttrs (env.screen-lock-command != null) {
                "Mod+Shift+Escape".spawn-sh = env.screen-lock-command;
              }
              // lib.optionalAttrs (env.launcher-command != null) {
                "Mod+Space".spawn-sh = env.launcher-command;
              }
              // lib.optionalAttrs (env.power-command != null) {
                "Mod+M".spawn-sh = env.power-command;
              };
            }
            // lib.optionalAttrs (env.lid-close-command != null) {
              switch-events.lid-close.spawn = [
                "sh"
                "-c"
                env.lid-close-command
              ];
            };
        };
        zsh.rc = [
          {
            lazy = false;
            content = ''
              alias deamonize="${lib.getExe self'.packages.niri} msg action spawn-sh --"
            '';
          }
        ];
      };
  };
}
