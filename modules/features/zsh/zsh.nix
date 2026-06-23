{ inputs, lib, ... }: {
  perSystem = { pkgs, lib, self', ... }: {
    packages.zsh =
      let
        runtimePkgs = [
          #TODO: add cutefetch, tldear

          # QoL
          pkgs.lsd    # ls  on steroids
          pkgs.bat    # cat on steroids
	  self'.packages.zsh-fast-syntax-highlighting
	  self'.packages.deja # Zsh Autosuggestions Improved
	  self'.packages.pure-prompt
          self'.packages.zoxide # cd  on steroids

          # General Purpose
          pkgs.ripgrep
          pkgs.fzf
          pkgs.curl
          pkgs.tree
          pkgs.wl-clipboard-rs

	  # Compression
	  pkgs.zip
	  pkgs.unzip
	  pkgs.gnutar

          # Code
	  self'.packages.git # TODO: Maybe add support for Jujutsu?
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
        ];
      in
      inputs.wrapper-modules.wrappers.zsh.wrap {
        inherit pkgs runtimePkgs;

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

	# concats passthru.zhrc from deps
        zshrc.content =
          lib.concatMapStrings (p: (p.passthru.zshrc or "") + "\n") runtimePkgs;

        zdotdir = ./configs;
      };
  };
}
