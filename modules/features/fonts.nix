{inputs, ...}: let
  fontPackages = pkgs: [
    # Nerd Fonts
    pkgs.nerd-fonts.jetbrains-mono

    # Sans-serif
    pkgs.aileron

    # Apple Fonts
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro
    inputs.apple-fonts.packages.${pkgs.system}.sf-mono
    inputs.apple-fonts.packages.${pkgs.system}.ny
  ];
in {
  flake.nixosModules.fonts = {pkgs, ...}: {
    fonts = {
      enableDefaultPackages = true;
      packages = fontPackages pkgs;
    };
  };

  flake.darwinModules.fonts = {pkgs, ...}: {
    fonts.packages = fontPackages pkgs;
  };
}
