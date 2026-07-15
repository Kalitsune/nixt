{ ... }: {
  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    {
      packages.anytype =
        if lib.hasSuffix "-darwin" system then
          pkgs.anytype
        else if system == "x86_64-linux" then
          # TEMPORARY: nixpkgs anytype 0.55.5 fails to build on Linux because bun tries to
          # extract optional platform-specific tarballs (@sentry/cli-win32-i686, etc.)
          # Use the official AppImage until the nixpkgs derivation is fixed.
          pkgs.appimageTools.wrapType2 {
            pname = "anytype";
            version = "0.55.5";
            src = pkgs.fetchurl {
              url = "https://github.com/anyproto/anytype-ts/releases/download/v0.55.5/Anytype-0.55.5.AppImage";
              hash = "sha256-uc28YFPR2ZNPW2I+eQjA7lyX74FoJdHIXH9qCA9yqx8=";
            };
          }
        else
          pkgs.anytype;
    };
}
