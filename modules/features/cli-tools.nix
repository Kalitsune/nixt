{ ... }:
{
  # Shared by zsh's PATH and environment.systemPackages (see collections.nix),
  # so the tools also work from sudo, scripts and non-zsh shells.
  perSystem =
    { pkgs, self', ... }:
    {
      packages.cli-tools = pkgs.buildEnv {
        name = "cli-tools";
        ignoreCollisions = true;
        paths = [

          # Nix
          self'.packages.nh # Nix Helper

          # QoL
          pkgs.lsd # ls  on steroids
          pkgs.bat # cat on steroids
          self'.packages.tldr # man +++
          self'.packages.zsh-completions
          self'.packages.zsh-fast-syntax-highlighting
          self'.packages.deja # Zsh Autosuggestions Improved
          self'.packages.pure-prompt
          self'.packages.cutefetch
          self'.packages.zoxide # cd  on steroids

          # General Purpose
          pkgs.ripgrep
          pkgs.jq
          pkgs.curl
          pkgs.tree
          pkgs.wl-clipboard-rs
          self'.packages.fzf

          # Compression
          pkgs.zip
          pkgs.unzip
          pkgs.gnutar

          # Code
          self'.packages.editor
          self'.packages.git # TODO: Maybe add support for Jujutsu?
          pkgs.git-lfs

          # Build systems
          pkgs.gnumake
          pkgs.just
          pkgs.meson

          # Forensics
          pkgs.file

          # Media
          pkgs.imagemagick
          pkgs.ffmpeg-full
          pkgs.pulseaudio
          pkgs.vips
        ];
      };
    };
}
