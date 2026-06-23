{
  description = "Dendritic Nix Config by Kalitsune";
  inputs = {
    nixpkgs.url =  "github:nixos/nixpkgs/nixos-unstable";

    # Dendritic Pattern Magic
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    # Fonts
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apps
    claude-desktop-linux = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake 
    {inherit inputs;} 
    (inputs.import-tree ./modules); # only imports .nix files that are not prefixed by _
}
