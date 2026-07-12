{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    packages.zsh-completions = let
      p = pkgs.zsh-completions;
    in
      p
      // {
        passthru =
          (p.passthru or {})
          // {
            zshrc =
              /*
              zsh
              */
              ''
                autoload -U compinit && compinit

                # Makes auto complete case insensitive
                       zstyle ':completion:*' match-list 'm:{a-z}={A-Za-z}'
              '';
            zsh-lazy = false; # Doesn't play nice with fzf-tab otherwise
          };
      };
  };
}
