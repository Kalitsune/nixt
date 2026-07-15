{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      packages.cutefetch =
        let
          p = inputs.cypkgs.packages.${system}.cutefetch;
        in
        p
        // {
          passthru = (p.passthru or { }) // {
            zshrc = ''
              alias fetch="MODE_CHOICE=\"kitty2\" EYES_CHOICE=\"0 1 2 3 4 6 7 8 11 12 14\" ${lib.getExe p} -r"
              fetch
            '';
            zsh-lazy = false;
          };
        };
    };
}
