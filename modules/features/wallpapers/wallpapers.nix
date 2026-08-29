{ self, ... }: {
  flake.nixosModules.wallpapers =
    {
      pkgs,
      lib,
      ...
    }:
    let
      sys = pkgs.stdenv.hostPlatform.system;
      change-wallpaper = self.packages.${sys}.change-wallpaper;
      noctalia = self.packages.${sys}.noctalia-shell;
    in
    {
      environment.systemPackages = [
        self.packages.${sys}.wallpapers
        change-wallpaper
      ];

      systemd.user.services.wallpaper-changer = {
        description = "Change desktop wallpaper";
        after = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        script = ''
          wallpaper=$(${lib.getExe change-wallpaper} --root-dir github:kalitsune/wallpapers --filter "$(cat "$HOME/.config/wallpaper-filter.txt" 2>/dev/null)")
          ${lib.getExe noctalia} ipc call wallpaper set "$wallpaper" || true
        '';
        serviceConfig.Type = "oneshot";
      };

      systemd.user.timers.wallpaper-changer = {
        description = "Periodically change desktop wallpaper";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnStartupSec = "5";
          OnUnitActiveSec = "1800";
        };
      };
    };

  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      meta = {
        maintainers = [ "kalitsune" ];
        license = lib.licenses.mit;
      };

      wallpapers = pkgs.stdenvNoCC.mkDerivation {
        pname = "wallpapers";
        version = "unstable-2026-07-09";

        src = pkgs.fetchgit {
          url = "https://github.com/kalitsune/wallpapers";
          rev = "39c288e6b5edd7789ac81c9055010dc216cafc8f";
          fetchLFS = true;
          hash = "sha256-cCt8v5cykYKkmAyX3CFhVXoUQ0E99HcfgIjcz3UWI+Y=";
        };

        dontBuild = true;

        installPhase = ''
          mkdir -p $out/share/wallpapers
          for dir in */; do
            cp -r "$dir" $out/share/wallpapers/
          done
        '';

        meta = meta // {
          description = "Kalitsune's wallpaper collection";
        };
      };

      change-wallpaper-base = pkgs.buildGoModule {
        pname = "change-wallpaper";
        version = "0.1.0";
        src = ./change_wallpaper;
        vendorHash = "sha256-WabGelav16AXeKStCqSw8ZxxhEOU+unqx4XoNiC68tU=";
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.vips.dev ];

        meta = meta // {
          description = "Little utility to pick random wallpapers";
          mainProgram = "change-wallpaper";
        };
      };

      mkChangeWallpaper =
        wallpaperRoot: extraDeps:
        pkgs.symlinkJoin {
          name = "change-wallpaper";
          paths = [ change-wallpaper-base ] ++ extraDeps;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/change-wallpaper \
              --set WALLPAPER_ROOT "${wallpaperRoot}"
          '';
          inherit (change-wallpaper-base) meta;
        };
    in
    {
      packages = {
        inherit wallpapers;
        change-wallpaper-bundled = mkChangeWallpaper "${wallpapers}/share/wallpapers" [ wallpapers ];
        change-wallpaper = mkChangeWallpaper "github:kalitsune/wallpapers" [ ];
      };
    };
}
