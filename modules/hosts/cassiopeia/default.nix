{ self, inputs, ... }: {

  flake.nixosConfigurations.Cassiopeia = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.CassiopeiaConfiguration # configuration.nix
      
      self.nixosModules.home-manager # dotfiles

      # Features
      self.nixosModules.niri
    ];
  };
}
