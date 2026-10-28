{ inputs, ... }: {
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    {
      # TODO: Remove external dep when merged (see: https://github.com/BirdeeHub/nix-wrapper-modules/pull/546)
      packages.ghostty =
        let
          repo = builtins.fetchTree {
            type = "github";
            owner = "TrustworthyAdult";
            repo = "nix-wrapper-modules";
            rev = "8dea37e1d510ee3687af092e6d08db385001551d";
            # narHash = "sha256-...";
          };
          ghostty-wrapper = import "${repo}/wrapperModules/g/ghostty/module.nix";
        in
        (inputs.wrapper-modules.lib.evalModule ghostty-wrapper).config.wrap {
          inherit pkgs;

          # Allows for the use of the compose key in Ghostty
          env.GTK_IM_MODULE = "ibus";

          settings = {
            # Aesthetics
            # Colors are pushed live by noctalia-shell's ghostty template (see
            # noctalia-shell.json activeTemplates) — it flips this to the
            # noctalia palette and rewrites it on every wallpaper/mode change.
            theme = "noctalia";
            # Opaque here: transparency is handled by niri's window-rule opacity
            # instead (see niri.nix), so the is-focused rule can actually make it
            # fully opaque — ghostty's own alpha would otherwise multiply on top
            # and stay translucent even when niri sets surface opacity to 1.0.
            background-opacity = 1.0;
            window-decoration = false;
            gtk-single-instance = false;
            # gtk-tabs-location = "hidden";

            keybind = [
              ## Tabs
              ### Control
              "alt+space>c=new_tab"
              "alt+space>n=next_tab"
              "alt+space>p=previous_tab"
              "alt+space>w=toggle_tab_overview"

              ## Splits
              ### Creation
              "alt+space>ù>right=new_split:right"
              "alt+space>ù>left=new_split:left"
              "alt+space>ù>up=new_split:up"
              "alt+space>ù>down=new_split:down"
              ### Navigation
              "alt+space>right=goto_split:right"
              "alt+space>left=goto_split:left"
              "alt+space>up=goto_split:up"
              "alt+space>down=goto_split:down"
              ### Resizing
              "alt+space>b>right=resize_split:right,10"
              "alt+space>b>left=resize_split:left,10"
              "alt+space>b>up=resize_split:up,10"
              "alt+space>b>down=resize_split:down,10"
              ### Misc
              "alt+space>equal=toggle_split_zoom"
              "alt+space>x=close_surface"

              # Misc
              "alt+space>escape=inspector:toggle"
              "alt+space>r=reload_config"

              # "global:alt+space=toggle_quick_terminal" # Require keys forwarding on wayland
            ];
          };
        };
    };
}
