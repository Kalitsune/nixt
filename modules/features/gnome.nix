{ ... }:
{
  flake.nixosModules.gnome =
    { pkgs, ... }:
    {
      services.xserver.enable = true;

      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

      environment.gnome.excludePackages = [ pkgs.epiphany ];

      environment.systemPackages = [
        pkgs.gnome-extension-manager
      ];
    };
}
