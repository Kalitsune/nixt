{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.epita-nixt = (import ./nixt-pie.nix { inherit pkgs; }).mkLauncher "epita-nixt" { };
  };
}
