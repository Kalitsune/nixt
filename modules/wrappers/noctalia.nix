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

      options.plugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "dotnetrob/cat" ];
        description = ''
          Plugin ids ("<author>/<plugin>"). Enabled in config; any not yet
          exported by Noctalia are fetched via `noctalia msg plugins enable`
          in the background after startup.
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

        settings = lib.mkMerge [
          (lib.mkIf (config.templates != { }) {
            theme.templates.user = config.templates;
          })
          (lib.mkIf (config.plugins != [ ]) {
            plugins.enabled = config.plugins;
          })
        ];

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
          # ponytail: sequential, polls 2min per plugin; add retry if flaky
          (lib.optionalString (config.plugins != [ ]) ''
            (
              _noc="${config.package}/bin/noctalia"
              _mat="''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/plugins/materialized"
              for _i in $(seq 60); do "$_noc" msg plugins list >/dev/null 2>&1 && break; sleep 2; done
              for _id in ${lib.escapeShellArgs config.plugins}; do
                set -- "$_mat"/*/"''${_id#*/}"
                [ -e "$1" ] && continue
                "$_noc" msg plugins enable "$_id" >/dev/null 2>&1
                for _i in $(seq 60); do
                  set -- "$_mat"/*/"''${_id#*/}"
                  [ -e "$1" ] && break
                  sleep 2
                done
              done
            ) >/dev/null 2>&1 &
          '')
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
