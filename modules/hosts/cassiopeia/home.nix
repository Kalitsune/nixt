{ self, ... }:
{
  flake.nixosModules.CassiopeiaHome =
    { ... }:
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.kalitsune = {
        imports = [ self.homeManagerModules.wallpapers ];
        home.stateVersion = "25.05";
      };
    };
}
