# Hardware for the Acer Aspire Switch 10 E (SW3-013)
#   Atom Z3735F (Bay Trail, 4C/4T), 2 GB soldered RAM, 32 GB Hynix eMMC
#   Intel HD Graphics (Gen7), 1280x800 IPS touchscreen
#   Realtek RTL8723BS WiFi/BT (SDIO), Realtek ALC5640 audio (Intel SST)
#   Kionix KXCJ9 accelerometer
#
# Mirrors what nixos-generate-config would emit, with the Bay Trail bits
# called out. Everything here is built into the kernel via nixpkgs'
# autoModules, so no kernel patching is required - which holds both for the
# stock 6.18 default and for the shared unstable testing kernel.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    # USB (the dock's port and the tablet's OTG port)
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"

    # eMMC behind sdhci-acpi - without this there is no root disk
    "sdhci_acpi"
    "mmc_block"

    # Bay Trail GPU: early KMS so the console comes up on the panel
    "i915"

    # Touch is I2C-HID on these panels rather than plain USB HID
    "i2c_hid_acpi"
    "hid_multitouch"
  ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
