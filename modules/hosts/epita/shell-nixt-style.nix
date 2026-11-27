{ self, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.epita-nixt = (import ./nixt-pie.nix { inherit pkgs self; }).mkLauncher "epita-nixt" { };
  };
}
