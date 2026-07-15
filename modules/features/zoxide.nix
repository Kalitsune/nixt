{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.zoxide =
        let
          p = pkgs.zoxide;
        in
        p
        // {
          passthru = (p.passthru or { }) // {
            zshrc = "eval \"$(${lib.getExe p} init --cmd cd zsh)\"";
          };
        };
    };
}
