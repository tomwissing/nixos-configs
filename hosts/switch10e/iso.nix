# Live installer image for the Acer Aspire Switch 10 E (SW3-013).
#
# The tablet ships with IA32 (32-bit) UEFI firmware on a 64-bit Atom and
# has no CSM/legacy boot option at all. The firmware therefore only ever
# looks for EFI/BOOT/BOOTIA32.EFI and silently ignores the stock NixOS
# image, which ships EFI/BOOT/BOOTX64.EFI only.
{ lib, ... }:

{
  # Build the image's GRUB for the i386-efi target (pkgsi686Linux.grub2_efi),
  # which makes iso-image.nix write EFI/BOOT/BOOTIA32.EFI instead of
  # BOOTX64.EFI. A 32-bit bootloader happily loads the 64-bit kernel, so the
  # system itself stays x86_64-linux.
  boot.loader.grub.forcei686 = true;

  # WiFi is a Realtek RTL8723BS hanging off SDIO. Nothing extra is needed
  # today: nixpkgs' autoModules builds the staging r8723bs module and
  # sdhci-acpi into the stock kernel, and the installer profile's
  # hardware.enableAllHardware already pulls in linux-firmware (which
  # carries rtlwifi/rtl8723bs_nic.bin). This is stated explicitly so that a
  # future kernel config change can't silently drop WiFi from the image.
  hardware.enableRedistributableFirmware = true;

  # SSH into the live session with the usual keys:
  #   ssh tom@<tablet>      (authorized keys come from modules/common.nix)
  # services.openssh and networking.networkmanager are already enabled by
  # the installer profile (nixos/modules/profiles/installation-device.nix).
  networking.networkmanager.enable = true;
  services.openssh.enable = true;
}
