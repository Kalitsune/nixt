{ self, ... }:
let
  pname = "solidcraft";
  version = "0.40.1";
in
{
  perSystem =
    { pkgs, ... }:
    let
      src = pkgs.fetchurl {
        url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-${version}-linux-x86_64.AppImage";
        hash = "sha256-fzF4x39TSyi0omOBCpQK2L8IjZt9mT12ZTeQOklRHC0=";
      };
      appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
    in
    {
      packages.solidcraft = pkgs.appimageTools.wrapType2 {
        inherit pname version src;
        extraInstallCommands = ''
          install -m 444 -D ${appimageContents}/io.tangencylabs.solidcraft.desktop -t $out/share/applications
          substituteInPlace $out/share/applications/io.tangencylabs.solidcraft.desktop \
            --replace-fail "Exec=solidcraft" "Exec=$out/bin/solidcraft"
          cp -r ${appimageContents}/usr/share/icons $out/share/
        '';
      };
    };

  flake.nixosModules.solidcraft =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.solidcraft
      ];
    };
}
