{ ... }:
{
  flake.nixosModules.vintagestory =
    { pkgs, lib, ... }:
    {
      services.flatpak = {
        enable = true;
        remotes = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
        packages = [
          { appId = "at.vintagestory.VintageStory"; origin = "flathub"; }
          # { appId = "<hytale-app-id>"; origin = "flathub"; } # add when released on flathub
        ];
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      xdg.mime.defaultApplications."x-scheme-handler/vintagestorymodinstall" = "at.vintagestory.VintageStory-vintagestorymodinstall.desktop";
    };
}
