{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      zsh.rc = [{ content = ''eval "$(${lib.getExe pkgs.zoxide} init --cmd cd zsh)"''; }];

      packages.zoxide = pkgs.zoxide;
    };
}
