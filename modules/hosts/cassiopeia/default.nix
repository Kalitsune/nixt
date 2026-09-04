{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.Cassiopeia = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-flatpak.nixosModules.nix-flatpak
      self.nixosModules.CassiopeiaConfiguration # configuration.nix
      self.nixosModules.CassiopeiaHome

      # Flake config
      self.nixosModules.nix

      # Features
      self.nixosModules.all
      self.nixosModules.gnome
      self.nixosModules.niri
      self.nixosModules.wallpapers
      self.nixosModules.programming-languages
      self.nixosModules.ios
      self.nixosModules.voxel-games
      self.nixosModules.vintagestory
      self.nixosModules.k8s
    ];
  };
}
