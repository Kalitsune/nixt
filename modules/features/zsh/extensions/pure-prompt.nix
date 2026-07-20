{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      zsh.rc = [
        {
          lazy = false;
          content = ''
            fpath+=("${pkgs.pure-prompt}/share/zsh/site-functions") \
            && autoload -U promptinit \
            && promptinit \
            && prompt pure
          '';
        }
      ];
      packages.pure-prompt = pkgs.pure-prompt;
    };
}
