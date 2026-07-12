{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.CassiopeiaHardware = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-intel"];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "/dev/mapper/luks-bdecc45a-25dc-417c-a880-cc9a429b1db8";
      fsType = "btrfs";
    };

    boot.initrd.luks.devices."luks-bdecc45a-25dc-417c-a880-cc9a429b1db8".device = "/dev/disk/by-uuid/bdecc45a-25dc-417c-a880-cc9a429b1db8";

    fileSystems."/home" = {
      device = "/dev/mapper/luks-bdecc45a-25dc-417c-a880-cc9a429b1db8";
      fsType = "btrfs";
      options = ["subvol=home"];
    };

    fileSystems."/nix" = {
      device = "/dev/mapper/luks-bdecc45a-25dc-417c-a880-cc9a429b1db8";
      fsType = "btrfs";
      options = ["subvol=nix"];
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/BB69-6D72";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    swapDevices = [
      {device = "/dev/mapper/luks-593718c8-b5e6-4a2c-8f94-f02831ef3241";}
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.npu.enable = true;
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
