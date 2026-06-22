{ self, inputs, ... }: {

  # Imports and configure home-manager
  flake.nixosModules.home-manager = { pkgs, ... }: {
    imports = [
      inputs.home-manager.nixosModules.default # This is the official home-manager
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };

  # This is my personnal home-manager configuration, it is populated through the relevant files
  # You are invited to do the same, although it only contains minimal information, only relevant to me, such as git author name, etc..
  flake.homeModules.kalitsune = { pkgs, ... }: {
    # TODO: make a global section instead of "[...].kalitsune" for those kind of options.
    home.stateVersion = "26.11";
  };

}
