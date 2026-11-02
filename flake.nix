{
  description = "Dendritic Nix Config by Kalitsune";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Dendritic Pattern Magic
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    # 3rd-party flakes
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent.url = "github:NousResearch/hermes-agent";

    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      # shell.nix, nixt-pie.nix and keybinds.nix are plain nix expressions, not flake-parts modules.
      inputs.import-tree.matchNot ".*/shell\\.nix|.*/nixt-pie\\.nix|.*/keybinds\\.nix" ./modules
    );
}
