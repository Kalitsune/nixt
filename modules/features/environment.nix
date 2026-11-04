{
  self,
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.environment =
      lib.genAttrs
        [
          "power-command"
          "launcher-command"
          "lid-close-command"
          "screen-lock-command"
        ]
        (name: lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Shell command for ${name}; consumers (e.g. niri) skip the feature when null.";
        });
  };

  config.perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      # System
      packages.desktop = self'.packages.niri;
      packages.terminal = self'.packages.ghostty;
      packages.shell = self'.packages.zsh;

      # Essential Apps
      packages.browser = pkgs.brave;
      packages.editor = self'.packages.helix;
      packages.file-explorer =
        if pkgs.stdenv.hostPlatform.isDarwin then
          pkgs.writeShellScriptBin "finder" ''
            if [ $# -gt 0 ]; then
              exec open -a Finder "$@"
            else
              exec open -a Finder .
            fi
          ''
        else
          pkgs.nautilus;
    };
}
