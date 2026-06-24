{ self, inputs, ... }: {

  flake.nixosConfigurations.Cassiopeia = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.CassiopeiaConfiguration # configuration.nix
      
      # Flake config
      self.nixosModules.nix

      # Features
      self.nixosModules.essentials
      self.nixosModules.niri
    ];
  };
}
