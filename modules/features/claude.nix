{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    self',
    system,
    ...
  }: {
    packages.claude-code = inputs.wrapper-modules.wrappers.claude-code.wrap {
      inherit pkgs;

      settings = {
        # Example config (see: https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/claude-code.html)
        includeCoAuthoredBy = false;
        permissions = {
          deny = [
            "Bash(sudo:*)"
            "Bash(rm -rf:*)"
          ];
        };
      };
    };

    packages.claude-desktop = inputs.claude-desktop-linux.packages.${system}.claude-desktop.override {
      nodePackages = {inherit (pkgs) asar;};
    };
  };
}
