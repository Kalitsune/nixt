{
  description = "Dendritic Nix Config by Kalitsune";
  inputs = {
    nixpkgs.url =  "github:nixos/nixpkgs/nixos-unstable";

    # Dendritic Pattern Magic
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake 
    {inherit inputs;} 
    (inputs.import-tree ./modules); # only imports .nix files that are not prefixed by _
}
