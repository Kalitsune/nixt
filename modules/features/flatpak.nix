{ ... }:
{
  flake.nixosModules.flatpak =
    { config, lib, ... }:
    {
      environment.sessionVariables = lib.mkIf config.services.flatpak.enable {
        XDG_DATA_DIRS = [
          "/var/lib/flatpak/exports/share"
          "$HOME/.local/share/flatpak/exports/share"
        ];
      };
    };
}
