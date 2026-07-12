{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.Cassiopeia = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.CassiopeiaConfiguration # configuration.nix

      # Flake config
      self.nixosModules.nix

      # Features
      self.nixosModules.all
      self.nixosModules.niri
      self.nixosModules.wallpapers
      self.nixosModules.programming-languages
      self.nixosModules.ios
    ];
  };
}
