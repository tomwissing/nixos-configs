# Acer Aspire Switch 10 E (SW3-013) - Bay Trail tablet / 2-in-1
#
# Initial install: build on the MSI, deliver the closure to the mounted
# target store, then use nixos-install --root /mnt --system <toplevel>.
# Identify the eMMC by its hardware ID in disko.nix: mmcblk numbering changes.
#
# Day-to-day: rebuild from the MSI, not from the tablet
#   nixos-rebuild switch --flake .#switch10e \
#     --target-host tom@switch10e --use-remote-sudo
{ config, pkgs, lib, ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "switch10e";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";
  services.xserver.xkb.layout = "de";

  # --- Bootloader ------------------------------------------------------
  # The SW3-013 has IA32 (32-bit) UEFI firmware and no CSM at all, so:
  #   * systemd-boot is impossible - NixOS ships no IA32 binary for it
  #   * GRUB must be built for i386-efi, which forcei686 does
  # A 32-bit GRUB loads the 64-bit kernel just fine; only the bootloader
  # is i686, the system itself stays x86_64-linux.
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      forcei686 = true;
      device = "nodev";
      efiInstallAsRemovable = true; # installs /EFI/BOOT/BOOTIA32.EFI
      configurationLimit = 5;       # 32 GB eMMC - keep generations short
      # Firmware drops Linux entries from BootOrder, even with the loader
      # marked trusted, but retains "Windows Boot Manager" at this path.
      # This is still IA32 GRUB loading NixOS; Windows is not installed.
      # Refresh the copy on every bootloader update, including kernel updates.
      # One-time firmware registration after installing (disk by hardware ID):
      # sudo efibootmgr --create --disk /dev/disk/by-id/mmc-HBG4e__0x6ffb64d0 \
      #   --part 1 --label 'Windows Boot Manager' \
      #   --loader '\EFI\Microsoft\Boot\bootmgfw.efi'
      extraInstallCommands = ''
        ${pkgs.coreutils}/bin/install -Dm0644 \
          "${config.boot.loader.efi.efiSysMountPoint}/EFI/BOOT/BOOTIA32.EFI" \
          "${config.boot.loader.efi.efiSysMountPoint}/EFI/Microsoft/Boot/bootmgfw.efi"
      '';
    };
    # Keep loader files independent of unreliable firmware boot variables.
    efi.canTouchEfiVariables = false;
  };

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  # 2 GB soldered RAM and no swap partition (swap would just wear the
  # eMMC) - compress idle pages in RAM instead.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # --- Desktop: XFCE ---------------------------------------------------
  # Chosen over Plasma for the 2 GB of RAM; autoLogin because there is no
  # disk encryption to type a password for.
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
  };
  services.displayManager = {
    defaultSession = "xfce";
    autoLogin = {
      enable = true;
      user = "tom";
    };
  };

  # --- Audio / Bluetooth / battery -------------------------------------
  # ALC5640 over Intel SST, Bluetooth on the same RTL8723BS chip.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.upower.enable = true;

  # --- Remote management -----------------------------------------------
  # Everything is built on the MSI and pushed here; this box never builds.
  services.openssh.enable = true;
  programs.git.enable = true;

  # Browser is the main app on a tablet; drop it if you disagree.
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;
  };

  # --- 32 GB eMMC housekeeping -----------------------------------------
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  documentation.doc.enable = false;
  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [
    vim
    htop
    efibootmgr
  ];

  # TODO: accelerometer (Kionix KXCJ9) auto-rotation is likely wrong or
  # missing - needs an ACPI/udev orientation quirk once we see it live.

  system.stateVersion = "26.05";
}
