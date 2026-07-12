{...}: {
  perSystem = {pkgs, ...}: {
    packages.wallpapers = pkgs.stdenv.mkDerivation {
      pname = "wallpapers";
      version = "unstable-2026-07-09";

      src = pkgs.fetchgit {
        url = "https://github.com/kalitsune/wallpapers";
        rev = "39c288e6b5edd7789ac81c9055010dc216cafc8f";
        fetchLFS = true;
        hash = pkgs.lib.fakeHash;
      };

      dontBuild = true;

      installPhase = ''
        mkdir -p $out/share/wallpapers
        for dir in */; do
          cp -r "$dir" $out/share/wallpapers/
        done
      '';
    };

    packages.change-wallpaper = pkgs.buildGoModule {
      pname = "change-wallpaper";
      version = "0.1.0";
      src = ./change_wallpaper;
      vendorHash = null;
    };
  };
}
