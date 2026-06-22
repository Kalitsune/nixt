{ self, inputs, ... }: {
  perSystem = { pkgs, lib, self', ...}: {
    packages.desktop = self'.packages.niri;
    packages.terminal = pkgs.ghostty;
    packages.shell = self'.packages.zsh;
  };  
}
