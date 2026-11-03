{
  self,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.obsidian.vault_path = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "~/Documents/Vault";
      description = "Path to Obsidian vault for theming.";
    };
  };

  config = {
    perSystem =
      {
        pkgs,
        lib,
        self',
        config,
        ...
      }:
      let
        obsidian_vault = config.obsidian.vault_path;
      in
      {
        packages.noctalia = (inputs.wrapper-modules.lib.evalModule self.wrappers.noctalia).config.wrap {
          inherit pkgs;

          runtimePkgs = [
            self'.packages.change-wallpaper
          ];

          settings = {
            location.auto_locate = true;

            shell = {
              screen_corners.enabled = true;
              screen_time_enabled = true;
              polkit_agent = true;
              password_style = "random";

              panel = {
                transparency_mode = "soft";
              };

              screenshot = {
                save_to_file = false;
                copy_to_clipboard = true;
                quality = 100;

                freeze_screen = true;
                annotate = true;
              };

              avatar_path = "~/.avatar";

              clipboard_enabled = false;

              external_ip_enabled = true;
            };

            idle.behavior = {
              lock = {
                enabled = true;
                timeout = 600;
                action = "lock";
              };
              screen-off = {
                timeout = 660;
                action = "screen_off"; # turns monitors off, and back on when you return
                enabled = true;
              };
              suspend = {
                enabled = true;
                timeout = 900;
                action = "lock_and_suspend"; # or action = "suspend" with lock_before_suspend = false
              };
            };

            lockscreen = {
              blurred_desktop = true; # shows actual desktop instead of wallpaper
            };

            lockscreen_widgets = {
              enabled = true;

              widget = {
                login = {
                  type = "login_box";
                  settings = {
                    show_caps_lock = true;
                    show_keyboard_layout = true;
                    show_login_button = true;
                    show_media = true;
                    show_password_reveal = true;
                    show_session_buttons = false;
                    show_unlock_hint = true;
                    show_weather = true;
                  };
                };
                clock_analog = {
                  type = "clock";
                  box_height = 200;
                  box_width = 200;
                  settings = {
                    clock_style = "analog";
                    color = "secondary";
                  };
                };
                clock_digital = {
                  type = "clock";
                  box_height = 200;
                  box_width = 575;
                  settings = {
                    clock_style = "digital";
                    color = "primary";
                  };
                };
              };
            };

            theme = {
              mode = "auto";
              source = "wallpaper";
              pure_black_dark = true;
              wallpaper_scheme = "m3-rainbow"; # prevents monochrome contrasts leading to themes making text hard to read

              templates = {
                enable_builtin_templates = true;
                builtin_ids = [
                  "gtk3"
                  "gtk4"
                  "qt"
                ]
                ++ lib.optional (self.lib.isLoaded ("niri")) "niri"
                ++ lib.optional (self.lib.isLoaded ("ghostty")) "ghostty"
                ++ lib.optional (self.lib.isLoaded ("helix")) "helix";

                enable_community_templates = true;
                community_ids =
                  [ ]
                  ++ lib.optional (obsidian_vault != null) "obsidian"
                  ++ lib.optional (self.lib.isLoaded ("firefox")) "pywalfox"
                  ++ lib.optional (self.lib.isLoaded ("vicinae")) "vicinae"
                  ++ lib.optional (self.lib.isLoaded ("neovim")) "neovim"
                  ++ lib.optional (self.lib.isLoaded ("thunderbird")) "thunderbird"
                  ++ lib.optional (self.lib.isLoaded ("prismlauncher")) "prismlauncher"
                  ++ lib.optional (self.lib.isLoaded ("steam")) "steam"
                  ++ lib.optional (self.lib.isLoaded ("opencode")) "opencode";

                user = {
                  hermes = {
                    input_path = "${./templates/hermes.yaml}";
                    output_path = "~/.hermes/skins/noctalia.yaml";
                  };
                }
                // lib.optionalAttrs (obsidian_vault != null) {
                  obsidian_extra = {
                    input_path = "${./templates/obsidian.css}";
                    output_path = "${obsidian_vault}/.obsidian/snippets/noctalia.css";
                  };
                };
              };
            };
            nightlight = {
              enabled = true;
              temperature_night = 5000;
            };

            backdrop = {
              enabled = true;
              blur_intensity = 0.5;
              tint_intensity = 0.1;
            };

            bar.default = {
              margin_ends = 0;

              capsule_group = [
                {
                  id = "control_center";
                  fill = "surface_container";
                  padding = 8;
                  members = [
                    "network"
                    "bluetooth"
                    "battery"
                  ];
                }
              ];

              start = [
                "workspaces"
                "spacer"
                "media"
              ];
              center = [ "clock" ];
              end = [
                "tray"
                "notifications"
                "volume"
                "brightness"
                "spacer"
                "group:control_center"
              ];

            };

            desktop_widgets.enabled = false;
            wallpaper = {
              enabled = true;
              fill_mode = "crop";
              fill_color = "#000000"; # fallback

              # wallpapers are managed by ipc. leave as is
              directory = "";
              automation.enabled = false;
            };

            control_center.shortcuts = [
              {
                type = "wifi";
              }
              {
                type = "bluetooth";
              }
              {
                type = "caffeine";
              }
              {
                type = "power_profile";
              }
              {
                type = "dark_mode";
              }
              {
                type = "nightlight";
              }
            ];

            notification = {
              history_retention_hours = 7 * 24; # one week
            };

            calendar = {
              enabled = true;
              dedupe_events = true;
              refresh_minutes = 10;
            };

          };
        };
      };
  };
}
