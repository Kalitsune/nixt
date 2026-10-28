{ lib, flake-parts-lib, ... }: {
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.niri.blurOpacity = lib.mkOption {
      type = lib.types.float;
      default = 0.7;
      description = "Opacity of unfocused translucent/blurred windows (ghostty, brave, obsidian, hermes).";
    };
  };
}
