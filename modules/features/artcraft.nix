{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.figcraft = pkgs.appimageTools.wrapType2 {
        pname = "figcraft";
        version = "0.17.0";
        src = pkgs.fetchurl {
          url = "https://github.com/storytold/figcraft/releases/download/v0.17.0/figcraft-0.17.0-linux-x86_64.AppImage";
          hash = "sha256-p0nZ+AdMvS3H0EoW1HJiABolKDkfoVO9bFxOT4TI5BQ=";
        };
      };
    };

  flake.nixosModules.artcraft =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.photocraft
        pkgs.vectorcraft
        self.packages.${pkgs.stdenv.hostPlatform.system}.figcraft
      ];
    };
}
