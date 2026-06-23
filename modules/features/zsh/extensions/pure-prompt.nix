{ inputs, lib, ... }: {
    perSystem = { pkgs, lib, self', ... }: {
      packages.pure-prompt = let 
        p = pkgs.pure-prompt;
      in p // {
        passthru = (p.passthru or {}) // {
          zshrc = ''
            fpath+=("${p}/share/zsh/site-functions") \
            && autoload -U promptinit \
            && promptinit \
            && prompt pure
          '';
        };
      };
  };
}
