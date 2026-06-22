{ self, inputs, ... }: {
  perSystem = {pkgs, lib, self', ...} : {
    packages.git = inputs.wrapper-modules.wrappers.git.wrap{
      inherit pkgs;

      settings = {
        # Used to setup identity by user.
	include.path = "~/.config/git/identity.conf";
	
	core.editor = "nvim"; # TODO: Switch to features/nvim when made
	init.defaultBranch = "main";	

	pull.rebase = false;
	push = {
	  default = "simple";
	  autoSetupRemote = true;
	};
	fetch.prune = true; # auto removes stale remote branch refs

	# TODO investigate interesting aliases
	# alias = {
        #   lg = "log --oneline --graph --all";
	# };
      };
    };
  };

  flake.homeModules.kalitsune = { pkgs, ... }: {
    home.file.".config/git/identity.conf".text = ''
[user]
  name="Kalitsune"
  email="git@kalitsune.net"
    '';
  };
}
