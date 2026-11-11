{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "msi-thin-gf63-12vf";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";
  services.xserver.xkb.layout = "de";

  age.identityPaths = [ "/root/.ssh/host_ed25519_key" ];

  # Bootloader (ESP on sda3 is shared only with NixOS; Windows boots from the NVMe ESP)
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
    ];

  # Hybrid graphics: Intel UHD renders by default, RTX 4060 Max-Q on demand
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    powerManagement.finegrained = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.displayManager = {
    plasma-login-manager.enable = true;
    autoLogin = {
      enable = true;
      user = "tom";
    };
  };
  services.desktopManager.plasma6.enable = true;

  # Unlock KWallet with the LUKS password on autologin (see NixOS wiki: KDE)
  systemd.services.plasmalogin.serviceConfig.KeyringMode = "inherit";
  security.pam.services.plasmalogin-autologin.rules.auth = {
    systemd_loadkey = {
      order = 0;
      control = "optional";
      modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
    };
    plasmalogin = {
      order = 1;
      control = "include";
      modulePath = "plasmalogin";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    fastfetch
  ];

  system.stateVersion = "26.05";
}
