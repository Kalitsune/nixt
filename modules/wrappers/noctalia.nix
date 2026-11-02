{ lib, ... }:
let
  noctaliaModule =
    {
      config,
      lib,
      wlib,
      pkgs,
      ...
    }:
    let
      tomlFmtType = wlib.types.structuredValueWith {
        nullable = false;
        typeName = "TOML";
      };
    in
    {
      imports = [ wlib.modules.default ];

      options.settings = lib.mkOption {
        type = tomlFmtType;
        default = { };
        description = ''
          Noctalia v5 configuration written to a nix-managed settings file.
          Noctalia merges all *.toml files in ~/.config/noctalia/.
        '';
        example = {
          theme = {
            mode = "dark";
            source = "builtin";
            builtin = "Noctalia";
          };
        };
      };

      options.templates = lib.mkOption {
        type = lib.types.attrsOf (
          wlib.types.structuredValueWith {
            nullable = false;
            typeName = "TOML";
          }
        );
        default = { };
        description = ''
          Shorthand for user templates. Merged into settings.theme.templates.user.
        '';
      };

      options.extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Extra TOML configuration appended to the generated config file.
        '';
      };

      config = {
        package = lib.mkDefault pkgs.noctalia;

        settings = lib.mkIf (config.templates != { }) {
          theme.templates.user = config.templates;
        };

        constructFiles.generatedSettings = {
          content = builtins.toJSON config.settings;
          relPath = "${config.binName}-config/noctalia/00-nix-settings.toml";
          builder = ''
            ${pkgs.remarshal}/bin/json2toml "$1" "$2"
            ${lib.optionalString (config.extraConfig != "") ''
              cat "$extraConfigPath" >> "$2"
            ''}
          '';
        };

        drv.extraConfig = config.extraConfig;
        drv.passAsFile = lib.optional (config.extraConfig != "") "extraConfig";

        # Compatibility symlink: noctalia-shell -> noctalia
        drv.postInstall = ''
          if [ -e "$out/bin/noctalia" ] && [ ! -e "$out/bin/noctalia-shell" ]; then
            ln -sf "$out/bin/noctalia" "$out/bin/noctalia-shell"
          fi
        '';

        runShell = [
          ''
            _noc_conf_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia"
            mkdir -p "$_noc_conf_dir"
            ln -sf "${config.constructFiles.generatedSettings.path}" \
              "$_noc_conf_dir/00-nix-settings.toml"
          ''
        ];
      };
    };
in
{
  options.flake.wrappers = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Flake wrapper blueprints.";
  };

  # Blueprint — exposed at flake.wrappers.noctalia.
  # This is a wrapper module function, not a derivation.
  # Callers evaluate it with inputs.wrapper-modules.lib.evalModule.
  config.flake.wrappers.noctalia = noctaliaModule;
  config.flake.wrappers.noctalia-shell = noctaliaModule;
}
