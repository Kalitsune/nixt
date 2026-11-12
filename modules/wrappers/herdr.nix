{ ... }:
{
  # Blueprint — exposed at flake.wrappers.herdr.
  # This is a wrapper module function, not a derivation.
  # Callers evaluate it with inputs.wrapper-modules.lib.evalModule.
  flake.wrappers.herdr =
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
          Herdr configuration written to a nix-managed `config.toml` and
          passed via `HERDR_CONFIG_PATH`.

          Every available option and its documentation live in the default
          config — run `herdr --default-config` to inspect them.
          See also: https://herdr.dev
        '';
        example = {
          theme.name = "catppuccin";
          terminal.new_cwd = "follow";
          ui = {
            sidebar_start_collapsed = false;
            pane_gaps = true;
          };
          "keys.prefix" = "ctrl+b";
        };
      };

      config = {
        package = lib.mkDefault pkgs.herdr;

        # Only override the host config when the user actually set options,
        # otherwise let herdr read ~/.config/herdr/config.toml as usual.
        envDefault.HERDR_CONFIG_PATH = lib.mkIf (config.settings != { }) (
          config.constructFiles.herdrConfig.path
        );

        constructFiles.herdrConfig = {
          content = builtins.toJSON config.settings;
          relPath = "${config.binName}-config/config.toml";
          builder = ''${pkgs.remarshal}/bin/json2toml "$1" "$2"'';
        };
      };
    };
}
