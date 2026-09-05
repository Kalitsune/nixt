{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.epita-nixt = (import ./nixt-pie.nix { inherit pkgs; }).mkShell { };
  };
}
