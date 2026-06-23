{ inputs, ...}: {
  perSystem = { pkgs, lib, ... }: {
    packages.deja = let
      p = pkgs.deja;
    in p // {
      passthru = (p.passthru or {}) // {
	zshrc = ''
          export DEJA_CYCLE_KEY=Ctrl+Tab
          eval "$(${ lib.getExe p } init zsh)"
	'';
      };
    };
  };
}
