{
  pkgs ? import <nixpkgs> { },
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # flakes
  nixt = builtins.getFlake "github:kalitsune/nixt";
  pie = builtins.getFlake "github:epita/nixpie";

  # override terminal to speed up downloading with the existing epita term
  nixtPackages = nixt.packages.${system} // {
    terminal = pie.inputs.nixpkgs.legacyPackages.${system}.rxvt-unicode;
  };
in
pkgs.mkShell {
  buildInputs = [
    nixtPackages.desktop
    nixtPackages.terminal
    nixtPackages.shell
    nixtPackages.editor
  ];
  shellHook = ''
    export SHELL=${pkgs.lib.getExe nixtPackages.shell} # Override default shell
    exec ${pkgs.lib.getExe nixtPackages.desktop}
  '';
}
