# Exposes packages.pie-installer — nix run github:kalitsune/nixt#pie-installer
# devShells are defined in shell-nixt-style.nix and shell-pie-style.nix.
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.pie-installer = pkgs.buildGoModule {
        pname = "pie-installer";
        version = "0.1.0";
        src = ./.;
        # Run `nix build` once; it will fail with the correct hash — paste it here.
        vendorHash = "sha256-xe6YFChN/8+mKf+2QQ0DgEhkljXTCAA6gjVufjDIXw0=";
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postInstall = ''
          wrapProgram $out/bin/pie-installer \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nix ]}
        '';
      };
    };
}
