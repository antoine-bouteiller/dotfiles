# Refresh hardware detection with `nixos-generate-config --show-hardware-config --no-filesystems`
# and keep the UUID-based storage configuration below.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = ["dm-snapshot"];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  # Single LUKS2 container holding an LVM root volume; no disk swap.
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/44f94999-339e-4976-a55f-f05fc19cf30e";
    allowDiscards = true; # NVMe TRIM through the LUKS mapping
    # TPM2 slot is enrolled post-install by `nix run .#secure-boot`; the passphrase
    # stays as the recovery path.
    crypttabExtraOpts = ["tpm2-device=auto"];
  };
  boot.initrd.services.lvm.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9bdd1509-3485-4ec9-afcb-301ffee62e2f";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D0FA-A16E";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };
  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
