{
  inputs,
  self,
  ...
}:
{
  flake.nixosModules.nix = { pkgs, ... }: {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5";
    };
    nix.settings.keep-outputs = false;
    nix.settings.keep-derivations = false;
    nixpkgs.config.allowUnfree = true;
    environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
  };
}
