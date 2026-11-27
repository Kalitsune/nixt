{ self, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.epita-pie =
      let
        common = import ./nixt-pie.nix { inherit pkgs self; };
      in
      common.mkLauncher "epita-pie" { desktop = common.desktops.niri { }; };
  };
}
