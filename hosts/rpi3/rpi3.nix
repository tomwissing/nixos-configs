{ config, pkgs, inputs, ... }:

{
  system.stateVersion = "25.05";
  imports = [
    #./hardware-configuration.nix
    ./wireguard.nix
    "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
  ];

  hardware.enableRedistributableFirmware = true;
  networking.tempAddresses = "enabled";

  # Hostname
  networking.hostName = "nixos_rpi3";

  # Networking
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "Europe/Berlin";

  # Bootloader
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # File system options
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9a6ffedb-a027-4ce4-915f-9e4382183442";
    fsType = "ext4";
    options = [ "noatime" "nodiratime" "commit=60" ];
  };
  fileSystems."/mnt/sd-boot" ={
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/mnt/sd-boot/boot";
    options = [ "bind" ];
  };

  # Kernel params
  boot.kernelParams = [ "panic=30" "boot.panic_on_fail" ];

  services.watchdogd.enable = true;

  boot.kernel.sysctl = {
    "vm.panic_on_oom" = 1;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    "vm.vfs_cache_pressure" = 200;
  };

  # Swap
  boot.kernel.sysctl."vm.swappiness" = 30;
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 35;
  };

  # System services
  services.openssh.enable = true;

  services.fstrim.enable = true;

  # Journald in RAM
  services.journald = {
      extraConfig = "MaxRetentionSec=1d";
  };

  nix = let commonServiceSettings = {
    automatic = true;
    persistent = true;
    dates = "weekly";
    randomizedDelaySec = "1h";
  };
  in {
    gc = commonServiceSettings // {
      options = "--delete-older-than 7d";
    };
    optimise = commonServiceSettings;
  };
}

