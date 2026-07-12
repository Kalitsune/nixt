{
  self,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.noctalia-shell = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;

      runtimePkgs = [pkgs.cliphist];

      settings =
        (builtins.fromJSON
          (builtins.readFile ./noctalia-shell.json)).settings;
    };
  };
}
