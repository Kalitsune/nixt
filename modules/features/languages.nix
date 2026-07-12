{...}: {
  flake.nixosModules.golang = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.go
      pkgs.gopls
      pkgs.golangci-lint
    ];
  };

  flake.nixosModules.python = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.python3
      pkgs.uv
      pkgs.pyright
    ];
  };

  flake.nixosModules.rust = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.rustup
      pkgs.rust-analyzer
    ];
  };

  flake.nixosModules.terraform = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.opentofu
      pkgs.tofu-ls
    ];
  };
}
