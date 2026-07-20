{ lib, flake-parts-lib, ... }: {
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.zsh.rc = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          content = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          lazy = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
      });
      default = [];
    };
  };
}
