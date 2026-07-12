{self, ...}: {
  flake.nixosModules.all = {...}: {
    imports = [
      self.nixosModules.essentials
      self.nixosModules.education
      self.nixosModules.entertainment
    ];
  };

  flake.nixosModules.programming-languages = {...}: {
    imports = [
      self.nixosModules.golang
      self.nixosModules.python
      self.nixosModules.rust
      self.nixosModules.terraform
    ];
  };

  flake.nixosModules.essentials = {pkgs, ...}: {
    imports = [self.nixosModules.tailscale];

    environment.systemPackages = [
      # Apps
      self.packages.${pkgs.stdenv.hostPlatform.system}.browser
      self.packages.${pkgs.stdenv.hostPlatform.system}.editor
      pkgs.beeper

      # Utils
      pkgs.mission-center
    ];
  };

  flake.nixosModules.education = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.anki
    ];
  };

  flake.nixosModules.entertainment = {pkgs, ...}: {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {LIBGL_ALWAYS_SOFTWARE = "1";};
      };
    };

    environment.systemPackages = [
      pkgs.stremio-linux-shell
    ];
  };
}
