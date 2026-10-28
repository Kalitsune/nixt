{ ... }:
{
  flake.nixosModules.netbird = { pkgs, ... }: {
    services.netbird.enable = true;

    networking.firewall.trustedInterfaces = [ "wt0" ];

    environment.systemPackages = [ pkgs.netbird-ui ];
  };

  perSystem = { ... }: {
    zsh.rc = [
      {
        lazy = false;
        content = /* zsh */ ''
          alias nb="netbird status"
        '';
      }
    ];
  };
}
