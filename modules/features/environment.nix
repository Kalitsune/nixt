{
  self,
  inputs,
  ...
}:
{
  perSystem =
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
