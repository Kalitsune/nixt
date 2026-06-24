{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.brave = pkgs.brave; 
  }; 
}
