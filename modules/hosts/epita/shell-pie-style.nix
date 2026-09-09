{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.epita-pie =
      let
        common    = import ./nixt-pie.nix { inherit pkgs; };
        nixtPkgs  = common.nixt.packages.${common.system};
        wrapNiri  = common.nixt.inputs.wrapper-modules.wrappers.niri.wrap;
        configmap = import ./niri-configmap.nix { inherit pkgs nixtPkgs; terminal = common.terminal; };
        desktop   = wrapNiri { inherit pkgs; settings = configmap; };
      in
      common.mkLauncher "epita-pie" { inherit desktop; };
  };
}
