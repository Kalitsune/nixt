{ ... }: {
  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    {
      packages.syncthing =
        if lib.hasSuffix "-darwin" system then
          pkgs.syncthing-macos
        else
          pkgs.syncthing.overrideAttrs (oldAttrs: {
            buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
              pkgs.syncthingtray
            ];
          });
    };
}
