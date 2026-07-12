{inputs, ...}: {
  perSystem = {
    self',
    pkgs,
    ...
  }: {
    packages.nh = inputs.wrapper-modules.wrappers.nh.wrap {
      inherit pkgs;

      flake = "~/nixt";
    };
  };
}
