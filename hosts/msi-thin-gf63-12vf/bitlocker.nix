{ config, lib, ... }:

let
  volumes = {
    windows = "ee3042c1-950d-4aa1-98a6-93267877728b";
    data = "cf7df457-0f8d-4b5d-a5cd-27b488944df5";
  };
  # With sysusers/userborn, agenix decrypts secrets in a service instead of
  # the activation script. Unlocking must wait for that service in this case.
  secretServices = lib.optionals
    (config.systemd.sysusers.enable || config.services.userborn.enable)
    [ "agenix-install-secrets.service" ];
in
{
  age.secrets = {
    bitlocker-windows.file = ../../secrets/bitlocker-windows.age;
    bitlocker-data.file = ../../secrets/bitlocker-data.age;
  };

  # Stage 2 only: agenix secrets are unavailable in the initrd.
  # noauto defers unlocking until the corresponding filesystem is accessed.
  environment.etc."crypttab".text = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: uuid:
      "bitlocker_${name} UUID=${uuid} ${config.age.secrets."bitlocker-${name}".path} bitlk,noauto,nofail,headless,x-systemd.device-timeout=10s"
    ) volumes) + "\n";

  systemd.services = lib.mapAttrs' (name: _: lib.nameValuePair
    "systemd-cryptsetup@bitlocker_${name}"
    {
      after = secretServices;
      requires = secretServices;
      # Extend the unit produced by systemd-cryptsetup-generator.
      overrideStrategy = "asDropin";
    }
  ) volumes;

  fileSystems = lib.mapAttrs' (name: _: lib.nameValuePair "/mnt/${name}" {
    device = "/dev/mapper/bitlocker_${name}";
    fsType = "ntfs3";
    options = [
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=15s"
      "x-systemd.requires=systemd-cryptsetup@bitlocker_${name}.service"
      "uid=1000"
      "gid=100"
      "umask=0077"
      "nosuid"
      "nodev"
    ];
  }) volumes;
}
