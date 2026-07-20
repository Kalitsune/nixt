{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      # Doesn't play nice with fzf-tab if deferred
      zsh.rc = [
        {
          lazy = false;
          content = /* zsh */ ''
            autoload -U compinit && compinit

            # Makes auto complete case insensitive
            zstyle ':completion:*' match-list 'm:{a-z}={A-Za-z}'
          '';
        }
      ];

      packages.zsh-completions = pkgs.zsh-completions;
    };
}
