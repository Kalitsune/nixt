{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.epita-pie =
      let
        common = import ./nixt-pie.nix { inherit pkgs; };
      in
      common.mkLauncher "epita-pie" { desktop = common.desktops.niri { }; };
  };
}
