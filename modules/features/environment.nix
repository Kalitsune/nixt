{ self, inputs, ... }: {
  perSystem = { pkgs, lib, self', ...}: {
    # System
    packages.desktop = self'.packages.niri;
    packages.terminal = self'.packages.ghostty;
    packages.shell = self'.packages.zsh;

    # Essential Apps
    packages.browser = self'.packages.brave;
    packages.file-explorer = if pkgs.stdenv.isDarwin then 
        pkgs.writeShellScriptBin "finder" ''
          if [ $# -gt 0 ]; then
            exec open -a Finder "$@"
          else
            exec open -a Finder .
          fi
        '' else pkgs.nautilus;
  };

  flake.nixosModules.essentials = { pkgs, ... }: { 
    environment.systemPackages = [
      # Apps
      self.packages.${ pkgs.stdenv.hostPlatform.system }.browser
    ];
  };
}
