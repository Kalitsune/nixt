{ ... }: {
  flake.nixosModules.tailscale = { pkgs, ... }: {
    services.tailscale.enable = true;
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
    };

    environment.systemPackages = [
      pkgs.trayscale
    ];
  };
}
