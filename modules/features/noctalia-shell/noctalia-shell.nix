{
  self,
  inputs,
  ...
}:
{
  perSystem = { pkgs, self', config, ... }: let
    inherit (pkgs) lib;
    vault = config.obsidian.vaultRoot;
  in {
    packages.noctalia-shell = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;

      # Because we supply more than just `settings` (user-templates,
      # preInstalledPlugins), the wrapper would otherwise point
      # NOCTALIA_CONFIG_DIR at the read-only nix store, so noctalia cannot write
      # colors.json and every theming pass fails. Copy the generated config to a
      # writable location on startup instead.
      outOfStoreConfig = ''"$HOME/.config/noctalia"'';
      autoCopyConfig = true;
      env.NOCTALIA_CONFIG_DIR = pkgs.lib.mkForce null;

      # wallpaper-changer plugin shells out to `change-wallpaper --msg ...`,
      # so the binary must be on the shell's runtime PATH.
      runtimePkgs = [
        pkgs.cliphist
        self'.packages.change-wallpaper
      ];

      settings = (builtins.fromJSON (builtins.readFile ./noctalia-shell.json)).settings;

      # Noctalia has no built-in Obsidian template, so ship ours as a user
      # template: it renders CSS vars into the vault's snippets dir (enable the
      # "noctalia" snippet in Obsidian → Appearance).
      user-templates.templates.obsidian = lib.mkIf (vault != null) {
        input_path = "${./templates/obsidian.css}";
        output_path = "${vault}/.obsidian/snippets/noctalia.css";
      };

      # Helix reloads config (and theme) on SIGUSR1.
      user-templates.templates.helix = {
        input_path = "${./templates/helix.toml}";
        output_path = "~/.config/helix/themes/noctalia.toml";
        post_hook = "pkill -USR1 -x hx || true";
      };

      user-templates.templates.hermes = {
        input_path = "${./templates/hermes.yaml}";
        output_path = "~/.hermes/skins/noctalia.yaml";
      };

      preInstalledPlugins.wallpaper-changer = {
        src = ./plugins/wallpaper-changer;
      };
    };
  };
}
