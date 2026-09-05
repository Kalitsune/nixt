{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.epita-pie =
      let
        common = import ./nixt-pie.nix { inherit pkgs; };
        nixtPkgs = common.nixt.packages.${common.system};
        noctalia_exe = pkgs.lib.getExe nixtPkgs.noctalia-shell;
        vicinae = pkgs.lib.getExe nixtPkgs.vicinae;
      in
      common.mkShell {
        desktop = nixtPkgs.niri.wrap {
          settings.binds = {
            "Mod+Enter".spawn-sh = pkgs.lib.getExe common.terminal;
            "Mod+T".spawn-sh = null;

            "Mod+Shift+E".spawn-sh = "${noctalia_exe} ipc call sessionMenu toggle";
            "Mod+M".spawn-sh = null;

            "Mod+Shift+Q".close-window = _: { };
            "Mod+X".close-window = null;

            "Mod+D".spawn-sh = "${vicinae} toggle";
            "Mod+Space".spawn-sh = null;
          };
        };
      };
  };
}
