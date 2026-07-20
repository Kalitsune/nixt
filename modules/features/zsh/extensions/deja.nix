{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      zsh.rc = [
        {
          content = ''
            export DEJA_CYCLE_KEY=Ctrl+Tab
            eval "$(${lib.getExe pkgs.deja} init zsh)"
          '';
        }
      ];
      packages.deja = pkgs.deja;
    };
}
