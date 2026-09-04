{ self, ... }: {
  flake.nixosModules.all = { ... }: {
    imports = [
      self.nixosModules.essentials
      self.nixosModules.extra
      self.nixosModules.education
      self.nixosModules.entertainment
    ];
  };

  flake.nixosModules.programming-languages = { ... }: {
    imports = [
      self.nixosModules.c
      self.nixosModules.golang
      self.nixosModules.nodejs
      self.nixosModules.python
      self.nixosModules.rust
      self.nixosModules.terraform
    ];
  };

  flake.nixosModules.essentials = { pkgs, ... }: {
    imports = [
      self.nixosModules.tailscale
      self.nixosModules.flatpak
    ];

    environment.systemPackages = [
      # Apps
      self.packages.${pkgs.stdenv.hostPlatform.system}.terminal
      self.packages.${pkgs.stdenv.hostPlatform.system}.browser
      self.packages.${pkgs.stdenv.hostPlatform.system}.editor
      self.packages.${pkgs.stdenv.hostPlatform.system}.syncthing
      pkgs.beeper
      pkgs.element-desktop
      pkgs.filezilla
      pkgs.localsend

      # Utils
      pkgs.mission-center
    ];
  };

  flake.nixosModules.extra = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.valent
      pkgs.figma-linux
    ];
  };

  flake.nixosModules.education = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.anki
    ];
  };

  flake.nixosModules.k8s = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      kubernetes-helm
      fluxcd
      kustomize
      talosctl
      kubectl
      sops
      age
    ];
  };

  flake.nixosModules.voxel-games = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.prismlauncher ];
  };

  flake.nixosModules.entertainment = { pkgs, ... }: {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {
          LIBGL_ALWAYS_SOFTWARE = "1";
        };
      };
    };

    environment.systemPackages = [
      pkgs.stremio-linux-shell
    ];
  };
}
