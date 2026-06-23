{ self, inputs, ... }: {
  perSystem = { pkgs, lib, self', ... }: {
    packages.claude-code = inputs.wrapper-modules.wrappers.claude-code.wrap{
      inherit pkgs;

      settings = {
      	  # Example config (see: https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/claude-code.html)
      	  includeCoAuthoredBy = false;
	  permissions = {
	    deny = [
	      "Bash(sudo:*)"
	      "Bash(rm -rf:*)"
	    ];
	  };
      };
    };
  };
}
