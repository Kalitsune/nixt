{ inputs, lib, ... }: {
  perSystem = { pkgs, lib, self', ... }: {
    packages.zsh = inputs.wrapper-modules.wrappers.zsh.wrap {
      inherit pkgs;

      runtimePkgs = [
      	#TODO: add cutefetch, tldear

	# Wrapped
	self'.packages.git # TODO: Maybe add support for Jujutsu?
      	
      	# QoL
	pkgs.zoxide
	pkgs.lsd    # ls on steroids
	pkgs.bat    # cat on steroids
	
	# General Purpose
	pkgs.ripgrep
	pkgs.fzf
	pkgs.curl
	pkgs.tree

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

      # Used to load runtime inputs.
      zshrc.content = ''
        # Pure Prompt
	fpath+=("${pkgs.pure-prompt}/share/zsh/site-functions") \
        && autoload -U promptinit \
	&& promptinit \
        && prompt pure

	# Zoxide - cd on steroid
	eval "$(${lib.getExe pkgs.zoxide} init --cmd cd zsh)"

	# Deja - ZSH Autocompletions Reloaded
	eval "$(${lib.getExe pkgs.deja} init zsh)"

	# Zsh Fast Syntax Highlighting
	source "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
      '';
    };
  };
}
