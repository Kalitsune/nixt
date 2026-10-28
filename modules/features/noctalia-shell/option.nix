{ lib, flake-parts-lib, ... }: {
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.obsidian.vaultRoot = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "~/Documents/MyVault";
      description = "Obsidian vault root. null = no Obsidian theming. Use ~ for portability.";
    };
  };
}
