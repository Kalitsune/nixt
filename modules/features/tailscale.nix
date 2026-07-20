{ ... }:
{
  flake.nixosModules.tailscale = { pkgs, ... }: {
    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
    };

    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
    };

    environment.systemPackages = [
      pkgs.trayscale
    ];
  };

  perSystem = { ... }: {
    zsh.rc = [{
      lazy = false;
      content = /* zsh */ ''
        alias ts="tailscale status"
        alias tsen="tailscale set --exit-nod"
      '';
    }];
  };
}
