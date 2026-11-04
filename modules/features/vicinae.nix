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
}
