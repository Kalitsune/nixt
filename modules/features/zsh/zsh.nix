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
      config,
      ...
    }:
    {
      packages.zsh =
        let
          runtimePkgs = [ self'.packages.cli-tools ];
        in
        inputs.wrapper-modules.wrappers.zsh.wrap {
          inherit pkgs runtimePkgs;

          env.EDITOR = lib.getExe self'.packages.editor;

          zshAliases = {
            # ls & Co
            ls = "lsd";
            ll = "ls -la";
            la = "ls -a";

            # Vim Addiction
            ":q" = "exit";

            # Fixes
            ssh = "TERM=xterm && ssh"; # Some remote hosts don't understand ghostty.
          };

          zshrc.content = ''
            export PATH="$HOME/.npm-global/bin:$PATH"
            source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
          ''
          + lib.concatStringsSep "\n" (
            lib.imap0 (
              i: entry:
              let
                fn = "_zsh_deferred_${toString i}";
              in
              if entry.content == "" then
                ""
              else if entry.lazy then
                ''
                  ${fn}() {
                  ${entry.content}
                  }
                  zsh-defer ${fn}''
              else
                entry.content
            ) config.zsh.rc
          );

          zdotdir = ./configs;
        };
    };
}
