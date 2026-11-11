# Acer Aspire Switch 10 E (SW3-013) - Bay Trail tablet / 2-in-1
#
# Initial install: build on the MSI, deliver the closure to the mounted
# target store, then use nixos-install --root /mnt --system <toplevel>.
# Identify the eMMC by its hardware ID in disko.nix: mmcblk numbering changes.
#
# Day-to-day: rebuild from the MSI, not from the tablet
#   nixos-rebuild switch --flake .#switch10e \
#     --target-host tom@switch10e --use-remote-sudo
{
  config,
  pkgs,
  lib,
  pkgsMainline,
  ...
}:

let
  sessionSetup = pkgs.writeShellApplication {
    name = "switch10e-session-setup";
    runtimeInputs = [
      pkgs.xfconf
      pkgs.xfce4-panel
      pkgs.gnugrep
      pkgs.coreutils
      pkgs.xset
    ];
    text = ''
      # Keep the display awake and prevent XFCE from suspending on inactivity.
      for source in ac battery; do
        xfconf-query -c xfce4-power-manager \
          -p "/xfce4-power-manager/inactivity-on-$source" -n -t uint -s 0
        xfconf-query -c xfce4-power-manager \
          -p "/xfce4-power-manager/lid-action-on-$source" -n -t uint -s 0
        # XFCE 4.20 uses 9 (seconds) to mean never dim the backlight.
        xfconf-query -c xfce4-power-manager \
          -p "/xfce4-power-manager/brightness-on-$source" -n -t uint -s 9
      done
      xfconf-query -c xfce4-power-manager \
        -p /xfce4-power-manager/dpms-enabled -n -t bool -s false
      # X11 screen blanking is independent of DPMS and xfce4-screensaver.
      xset s off

      # Wait for the stock top panel to be created on a new user account.
      panel=/panels/panel-1/plugin-ids
      ready=false
      for ((attempt = 0; attempt < 20; attempt++)); do
        if ids=$(xfconf-query -c xfce4-panel -p "$panel" 2>/dev/null); then
          ready=true
          break
        fi
        sleep 1
      done
      "$ready" || exit 1

      xfconf-query -c xfce4-power-manager \
        -p /xfce4-power-manager/show-panel-label -n -t int -s 1

      # Keep the user's existing items and avoid adding the indicator twice.
      mapfile -t ids < <(printf '%s\n' "$ids" | grep -E '^[0-9]+$')
      for id in "''${ids[@]}"; do
        if [[ $(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id") == power-manager-plugin ]]; then
          exit 0
        fi
      done
      id=1
      while xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" >/dev/null 2>&1; do
        id=$((id + 1))
      done
      xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" \
        -n -t string -s power-manager-plugin

      # Place it before the clock, or at the end if there is no clock.
      args=()
      inserted=false
      for existing in "''${ids[@]}"; do
        if ! "$inserted" && [[ $(xfconf-query -c xfce4-panel -p "/plugins/plugin-$existing") == clock ]]; then
          args+=(-t int -s "$id")
          inserted=true
        fi
        args+=(-t int -s "$existing")
      done
      if ! "$inserted"; then
        args+=(-t int -s "$id")
      fi
      xfconf-query -c xfce4-panel -p "$panel" -a "''${args[@]}"
      # The running panel reads its plugin list at startup.
      xfce4-panel --restart >/dev/null 2>&1 &
    '';
  };
in
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "switch10e";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";
  services.xserver.xkb.layout = "de";

  # --- Kernel: mainline 7.4-rc1 ----------------------------------------
  # 7.4 moves RTL8723BS off the (now deleted) staging driver and onto the
  # mac80211-based rtw88 driver. No boot.kernelPatches is needed:
  # x86_64's platform sets autoModules, which answers "m" to every
  # tristate, so CONFIG_RTW88_8723BS comes out =m (it only `depends on
  # MMC`, which the eMMC root guarantees). Verified against the generated
  # config. Adding it via structuredExtraConfig anyway would produce an
  # identical .config but a different derivation, trading the prebuilt
  # kernel on cache.nixos.org for a full local compile.
  # The firmware it wants, rtw88/rtw8723b_fw.bin, is already in the
  # linux-firmware 20261019 that enableRedistributableFirmware pulls in.
  boot.kernelPackages = pkgsMainline.linuxPackages_testing;

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
      configurationLimit = 5; # 32 GB eMMC - keep generations short
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
    desktopManager.xfce = {
      enable = true;
      enableScreensaver = false;
    };
    displayManager.lightdm.enable = true;
  };
  services.displayManager = {
    defaultSession = "xfce";
    autoLogin = {
      enable = true;
      user = "tom";
    };
  };

  # Ignore lid-close and idle sleep requests, while preserving the power
  # button's normal shutdown behavior.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
  };

  environment.etc."xdg/autostart/switch10e-session-setup.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Switch 10 E session setup
    Exec=${sessionSetup}/bin/switch10e-session-setup
    OnlyShowIn=XFCE;
    Terminal=false
  '';

  environment.etc."xdg/autostart/switch10e-firefox.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Home Assistant kiosk
    Exec=${pkgs.firefox-esr}/bin/firefox --kiosk https://home.sh.tomwissing.de
    OnlyShowIn=XFCE;
    Terminal=false
  '';

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
  # Deduplicate the store daily at low priority, only on AC power.
  nix.optimise.automatic = true;
  documentation.doc.enable = false;
  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [
    vim
    htop
    efibootmgr
    usbutils
  ];

  # TODO: accelerometer (Kionix KXCJ9) auto-rotation is likely wrong or
  # missing - needs an ACPI/udev orientation quirk once we see it live.

  system.stateVersion = "26.05";
}
