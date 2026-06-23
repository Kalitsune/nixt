{ self, inputs, ... }: {
  perSystem = { pkgs, lib, self', ...}: {
    packages.desktop = self'.packages.niri;
    packages.terminal = self'.packages.ghostty;
    packages.shell = self'.packages.zsh;
  };  
}
