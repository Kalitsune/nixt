{ self, inputs, ... }: {
  # Standalone home-manager config.
  # meant to be used on non-nixos devices using the home-manager command.
  flake.homeConfiguration.kalitsune = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { system = builtins.currentSystem; }; 
    modules = [
      self.homeModules.kalitsune
      {
        home.username = "kalitsune";
	home.homeDirectory = "/home/kalitsune";
      }
    ];
  };
}
