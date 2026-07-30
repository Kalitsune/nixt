{ ... }:
{
  # Blueprint — exposed at self.packages.wrappers.vicinae.
  # This is a wrapper module function, not a derivation.
  # Callers evaluate it with inputs.wrapper-modules.lib.evalModule.
  flake.wrappers.vicinae =
    {
      config,
      lib,
      wlib,
      pkgs,
      ...
    }:
    let
      jsonFmtType = wlib.types.structuredValueWith { typeName = "JSON"; };
    in
    {
      imports = [ wlib.modules.default ];

      options.settings = lib.mkOption {
        type = jsonFmtType;
        default = { };
        description = ''
          Vicinae configuration written to a nix-managed settings file.

          All options and their documentation live in the default config —
          run `vicinae config default` to inspect them.
          See also: https://docs.vicinae.com/config

          On first launch the wrapper creates
          `~/.config/vicinae/settings.json` (if absent) with an import
          pointing at the nix-generated file. Values set there — including
          anything changed through the GUI — override the nix settings,
          because vicinae gives the user file higher precedence than its
          imports.
        '';
        example = {
          escape_key_behavior = "close_window";
          search_files_in_root = true;
          font.normal = {
            family = "Fira Sans";
            size = 11.0;
          };
          theme = {
            light = {
              name = "vicinae-light";
              icon_theme = "auto";
            };
            dark = {
              name = "vicinae-dark";
              icon_theme = "auto";
            };
          };
          launcher_window = {
            opacity = 0.97;
            blur.enabled = true;
            layer_shell = {
              enabled = true;
              keyboard_interactivity = "on_demand";
              layer = "top";
            };
          };
          keybinds = {
            "open-search-filter" = "control+P";
            "open-settings" = "control+comma";
            "toggle-action-panel" = "control+B";
          };
          favorites = [ "clipboard:history" ];
          fallbacks = [ "files:search" ];
        };
      };

      config = {
        package = lib.mkDefault pkgs.vicinae;

        constructFiles.generatedSettings = {
          content = builtins.toJSON config.settings;
          relPath = "vicinae-nix-settings.json";
        };

        # On each invocation: refresh the nix-settings symlink and bootstrap
        # a settings.json that imports it if none exists yet.
        runShell = [
          ''
            _vic_conf_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/vicinae"
            mkdir -p "$_vic_conf_dir"
            ln -sf "${config.constructFiles.generatedSettings.path}" \
              "$_vic_conf_dir/nix-settings.json"
            if [ ! -f "$_vic_conf_dir/settings.json" ]; then
              printf '{"$schema":"https://vicinae.com/schemas/config.json","imports":["nix-settings.json"]}' \
                > "$_vic_conf_dir/settings.json"
            fi
          ''
        ];
      };
    };
}
