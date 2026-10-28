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
      noctalia-shell = self.packages.${sys}.noctalia-shell;
    in
    {
      environment.systemPackages = [
        self.packages.${sys}.wallpapers
        change-wallpaper
      ];

      # Supervised daemon. It used to be a niri spawn-at-startup entry, which
      # nothing restarts: one crash (or one log.Fatal on a network blip) froze
      # the wallpaper until the next login.
      systemd.user.services.wallpaper-daemon = {
        description = "Pick and apply wallpapers, and serve the control socket";
        # graphical-session.target is reached by the compositor, which must be
        # up before `noctalia-shell ipc call` can apply anything.
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        # noctalia-shell must be on PATH: change-wallpaper --apply=noctalia
        # shells out to it by name.
        path = [ noctalia-shell ];

        serviceConfig = {
          Type = "simple";
          # Persistent output path: without --output the picked image lands in
          # $TMPDIR, which is wiped between boots, so noctalia ends up pointing
          # at a deleted file and shows no wallpaper after a restart.
          StateDirectory = "wallpaper";
          # %h = home, %t = XDG_RUNTIME_DIR, %S = state dir root.
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe change-wallpaper)
            "--filter-file=%h/.config/wallpaper-filter.txt"
            "--output=%S/wallpaper/current.png"
            "--apply=noctalia"
            # Control socket the noctalia wallpaper-changer plugin talks to
            # (trigger a change, list collections, set the filter).
            "--socket=%t/change-wallpaper.sock"
            "--daemon"
          ];
          Restart = "always";
          RestartSec = 5;
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
