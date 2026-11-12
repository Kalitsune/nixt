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
      ...
    }:
    {
      packages.herdr = (inputs.wrapper-modules.lib.evalModule config.flake.wrappers.herdr).config.wrap {
        inherit pkgs;
        settings = {

          onboarding = false;

          ui = {
            sidebar_start_collapsed = false;
            pane_gaps = true;
          };
          keys = {
            prefix = "ctrl+space";

            new_workspace = "prefix+shift+c";
            rename_workspace = "prefix+shift+r";
            close_workspace = "prefix+shift+x";
            previous_workspace = "prefix+shift+p";
            next_workspace = "prefix+shift+n";

            workspace_picker = "prefix+w";
            goto = "prefix+space";

            detach = "prefix+q";

            new_tab = "prefix+c";
            rename_tab = "prefix+r";
            close_tab = "prefix+x";
            previous_tab = "prefix+p";
            next_tab = "prefix+n";
          };
        };
      };
    };
}
