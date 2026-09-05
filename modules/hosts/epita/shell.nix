{
  pkgs ? import <nixpkgs> { },
}:
import ./shell-pie-compliant.nix { inherit pkgs; }
