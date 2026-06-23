{ inputs, self, ... }: {
  flake.nixosModules.nix = { pkgs, ... }: {

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = true;
    environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
  };
}
