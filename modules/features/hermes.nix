{ inputs, ... }: {
  flake.nixosModules.hermes = { pkgs, ... }: {
    environment.systemPackages =
      with inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
      [
        default # hermes-agent CLI
        desktop # hermes-desktop GUI (separate derivation, not bundled in default)
      ];
  };
}
