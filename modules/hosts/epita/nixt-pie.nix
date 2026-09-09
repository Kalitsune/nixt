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

  mkLauncher =
    name: extraPackages:
    let
      packages = basePackages // extraPackages;
    in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        packages.terminal
        packages.editor
      ];
      text = ''
        export SHELL=${pkgs.lib.getExe packages.shell}
        exec ${pkgs.lib.getExe packages.desktop}
      '';
    };
}
