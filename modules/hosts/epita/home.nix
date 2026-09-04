{ self, inputs, ... }:
let
  user = builtins.getEnv "USER";
  mkHome =
    username:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        self.homeManagerModules.wallpapers
        {
          home.username = username;
          home.homeDirectory = "/home/${username}";
          home.stateVersion = "25.05";
        }
      ];
    };
in
{
  flake.homeConfigurations.epita = mkHome user;
}
