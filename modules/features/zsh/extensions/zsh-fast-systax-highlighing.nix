{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    zsh.rc = [{ content = "source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"; }];

    packages.zsh-fast-syntax-highlighting = pkgs.zsh-fast-syntax-highlighting;
  };
}
