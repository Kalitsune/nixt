{
  self,
  config,
  inputs,
  ...
}:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      environment.launcher-command = lib.mkIf (self.lib.isLoaded "vicinae") "${lib.getExe self'.packages.vicinae} toggle";

      packages.vicinae =
        (inputs.wrapper-modules.lib.evalModule config.flake.wrappers.vicinae).config.wrap
          {
            inherit pkgs;

            settings = {
              escape_key_behavior = "close_window";

              launcher_window = {
                opacity = 0.97;
                blur.enabled = true;

                # "exclusive" breaks mouse interaction on popups in some
                # Wayland compositors, including niri.
                layer_shell.keyboard_interactivity = "on_demand";
              };
            };
          };
    };

  # Vicinae watches the app dir by path, but a switch swaps the /run/current-system
  # symlink, so the old watch goes stale. Restart the server when it changes.
  flake.nixosModules.vicinae =
    { pkgs, ... }:
    {
      environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.vicinae ];

      systemd.user.paths.vicinae-reload = {
        wantedBy = [ "graphical-session.target" ];
        pathConfig.PathChanged = "/run/current-system";
      };
      systemd.user.services.vicinae-reload = {
        # oneshot + transient unit: a long-running service would stay "active" and
        # swallow later path triggers. --replace kills the previous server.
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart = "${pkgs.systemd}/bin/systemd-run --user --collect ${
          self.packages.${pkgs.stdenv.hostPlatform.system}.vicinae
        }/bin/vicinae server --replace";
      };
    };
}
