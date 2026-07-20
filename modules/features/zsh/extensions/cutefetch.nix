{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      cutefetch = inputs.cypkgs.packages.${system}.cutefetch;
    in
    {
      zsh.rc = [
        {
          lazy = false;
          content = ''
            alias fetch="MODE_CHOICE=\"kitty2\" EYES_CHOICE=\"0 1 2 3 4 6 7 8 11 12 14\" ${lib.getExe cutefetch} -r"
            fetch
          '';
        }
      ];

      packages.cutefetch = cutefetch;
    };
}
