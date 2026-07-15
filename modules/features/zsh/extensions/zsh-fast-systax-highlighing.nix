{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.zsh-fast-syntax-highlighting =
      let
        p = pkgs.zsh-fast-syntax-highlighting;
      in
      p
      // {
        passthru = (p.passthru or { }) // {
          zshrc = "source ${p}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
        };
      };
  };
}
