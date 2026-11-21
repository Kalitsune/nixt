{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # Not in nixpkgs: wrap AppImage, export .desktop + icon so launchers see it.
      appimage =
        {
          pname,
          version,
          url,
          hash,
          id,
        }:
        let
          src = pkgs.fetchurl { inherit url hash; };
          extracted = pkgs.appimageTools.extract { inherit pname version src; };
        in
        pkgs.appimageTools.wrapType2 {
          inherit pname version src;
          extraInstallCommands = ''
            install -Dm444 ${extracted}/${id}.desktop -t $out/share/applications
            for d in ${extracted}/usr/share/icons/hicolor/*/apps/${id}.png; do
              s=$(basename $(dirname $(dirname $d)))
              install -Dm444 $d $out/share/icons/hicolor/$s/apps/${id}.png
            done
          '';
        };

      withThemeFile =
        pkg:
        pkgs.symlinkJoin {
          inherit (pkg) name pname version;
          paths = [ pkg ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/${pkg.pname} --run \
              'set -- --theme-file "''${XDG_CONFIG_HOME:-$HOME/.config}/solidcraft/noctalia-theme.json" "$@"'
          '';
        };
    in
    {
      packages.figcraft = appimage {
        pname = "figcraft";
        version = "0.17.0";
        url = "https://github.com/storytold/figcraft/releases/download/v0.17.0/figcraft-0.17.0-linux-x86_64.AppImage";
        hash = "sha256-p0nZ+AdMvS3H0EoW1HJiABolKDkfoVO9bFxOT4TI5BQ=";
        id = "ai.storyteller.figcraft";
      };

      # --theme-file: follows the Noctalia-rendered theme live (noctalia.nix template).
      packages.solidcraft = withThemeFile (appimage {
        pname = "solidcraft";
        version = "0.45.0";
        url = "https://github.com/tangency-labs/solidcraft/releases/download/v0.45.0/solidcraft-0.45.0-linux-x86_64.AppImage";
        hash = "sha256-rEUzhf/UXtWcYQS8wwqgHLhTvP4zi96qfkLCTMbNHC8=";
        id = "io.tangencylabs.solidcraft";
      });
    };

  flake.nixosModules.artcraft =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.photocraft
        pkgs.vectorcraft
        self.packages.${pkgs.stdenv.hostPlatform.system}.figcraft
        self.packages.${pkgs.stdenv.hostPlatform.system}.solidcraft
      ];
    };
}
