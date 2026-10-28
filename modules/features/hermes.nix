{ inputs, ... }: {
  flake.nixosModules.hermes = { pkgs, ... }: {
    environment.systemPackages =
      with inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
      [
        default # hermes-agent CLI
        desktop # hermes-desktop GUI (separate derivation, not bundled in default)
      ];

    # Hermes downloads dynamically-linked binaries (agent-browser, Playwright
    # Chromium) that need an FHS-compatible linker and shared libraries.
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      # glibc basics (agent-browser)
      glibc

      # Chromium / Electron runtime deps
      nspr
      nss
      cups
      expat
      dbus
      glib
      atk
      at-spi2-atk
      at-spi2-core
      libxkbcommon
      mesa # libgbm
      cairo
      pango
      alsa-lib
      udev

      # X11 libs (Chromium uses Xwayland fallback)
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
    ];
  };
}
