{ pkgs }:
let
  system = pkgs.stdenv.hostPlatform.system;
  nixt = builtins.getFlake "github:kalitsune/nixt";
  pie = builtins.getFlake "github:epita/nixpie";
  terminal = pie.inputs.nixpkgs.legacyPackages.${system}.rxvt-unicode;
  basePackages = nixt.packages.${system} // { inherit terminal; };
in
{
  inherit system nixt pie terminal;

  mkShell =
    extraPackages:
    let
      packages = basePackages // extraPackages;
    in
    pkgs.mkShell {
      buildInputs = [
        packages.terminal
        packages.editor
      ];
      shellHook = ''
        export SHELL=${pkgs.lib.getExe packages.shell}
        exec ${pkgs.lib.getExe packages.desktop}
      '';
    };
}
