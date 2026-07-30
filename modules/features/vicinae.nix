{ config, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.vicinae =
        (inputs.wrapper-modules.lib.evalModule config.flake.wrappers.vicinae).config.wrap {
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
