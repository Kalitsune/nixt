{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.fzf =
        let
          p = pkgs.fzf;
        in
        p
        // {
          passthru = (p.passthru or { }) // {
            zshrc = ''
              eval "$(${lib.getExe p} --zsh)"
              source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

              zstyle ':completion:*' menu no

              zstyle ':completion:*' list-colors $${(s.:.)LS_COLORS}

              zstyle ':fzf-tab:complete:cd:*' fzf-preview '${lib.getExe pkgs.lsd} --color=always --icon=always $realpath'

            '';
          };
        };
    };
}
