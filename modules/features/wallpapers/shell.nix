{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  nativeBuildInputs = [ pkgs.pkg-config ]; # Provides the tool and sets up hooks
  buildInputs = [
    pkgs.vips.dev
  ];
}
