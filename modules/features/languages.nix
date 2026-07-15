{ ... }: {
  flake.nixosModules.golang = { pkgs, ... }: {
    environment = {
      systemPackages = [
        pkgs.go
        pkgs.gopls
        pkgs.golangci-lint
        pkgs.gcc
        pkgs.pkg-config
      ];
      variables.CGO_ENABLED = "1";
    };
  };

  flake.nixosModules.python = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.python3
      pkgs.uv
      pkgs.pyright
    ];
  };

  flake.nixosModules.rust = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.rustup
      pkgs.rust-analyzer
    ];
  };

  flake.nixosModules.c = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.gcc
      pkgs.gdb
      pkgs.cmake
      pkgs.pkg-config
      pkgs.clang-tools # clangd LSP
    ];
  };

  flake.nixosModules.terraform = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.opentofu
      pkgs.tofu-ls
    ];
  };
}
