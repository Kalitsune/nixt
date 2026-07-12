{...}: {
  flake.nixosModules.tailscale = {...}: {
    services.tailscale.enable = true;
    networking.firewall = {
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [41641];
    };
  };

  perSystem = {
    pkgs,
    ...
  }: {
    packages.tailscale = let
      p = pkgs.tailscale;
    in
      p
      // {
        passthru =
          (p.passthru or {})
          // {
            zshrc = ''
              alias ts="tailscale status"
              alias tsen="tailscale set --exit-node"
              alias tsend="tailscale file cp"
              alias tget="tailscale file get"
            '';
          };
      };
  };
}
