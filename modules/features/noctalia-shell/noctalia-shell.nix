{
  self,
  inputs,
  ...
}:
{
  perSystem = { pkgs, self', ... }: {
    packages.noctalia-shell = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;

      runtimePkgs = [ pkgs.cliphist self'.packages.change-wallpaper ];

      settings = (builtins.fromJSON (builtins.readFile ./noctalia-shell.json)).settings;
    };
  };
}
