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
          runtimePkgs = [

            # Nix
            self'.packages.nh # Nix Helper

            # QoL
            pkgs.lsd # ls  on steroids
            pkgs.bat # cat on steroids
            self'.packages.tldr # man +++
            self'.packages.zsh-completions
            self'.packages.zsh-fast-syntax-highlighting
            self'.packages.deja # Zsh Autosuggestions Improved
            self'.packages.pure-prompt
            self'.packages.cutefetch
            self'.packages.zoxide # cd  on steroids

            # General Purpose
            pkgs.ripgrep
            pkgs.jq
            pkgs.curl
            pkgs.tree
            pkgs.wl-clipboard-rs
            self'.packages.fzf

            # Compression
            pkgs.zip
            pkgs.unzip
            pkgs.gnutar

            # Code
            self'.packages.editor
            self'.packages.git # TODO: Maybe add support for Jujutsu?
            pkgs.git-lfs
            self'.packages.claude-code

            # Build systems
            pkgs.gnumake
            pkgs.just
            pkgs.meson

            # Forensics
            pkgs.file

            # Media
            pkgs.imagemagick
            pkgs.ffmpeg-full
            pkgs.pulseaudio
            pkgs.vips
          ];
        in
        inputs.wrapper-modules.wrappers.zsh.wrap {
          inherit pkgs runtimePkgs;

          env.EDITOR = "${self'.packages.editor}/bin/nvim";

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
