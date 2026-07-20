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
            eval "$(${lib.getExe pkgs.fzf} --zsh)"
            source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

            zstyle ':completion:*' menu no

            zstyle ':completion:*' list-colors $${(s.:.)LS_COLORS}

            zstyle ':fzf-tab:complete:cd:*' fzf-preview '${lib.getExe pkgs.lsd} --color=always --icon=always $realpath'
          '';
        }
      ];

      packages.fzf = pkgs.fzf;
    };
}
