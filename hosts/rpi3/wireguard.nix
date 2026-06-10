{ config, pkgs, lib, ... }:
{
  age.secrets.wireguard-pr.file = ../../secrets/rpi3-wireguard-pr.age;
  age.secrets.wireguard-sh.file = ../../secrets/rpi3-wireguard-sh.age;

  networking.wg-quick.interfaces.wg0 = {
    # Bring up interface at boot
    autostart = true;
    table = "off";

    # Interface configuration
    address = [ "10.7.0.5/24" ];
    dns = [ "94.140.14.14" "94.140.15.15" ];

    privateKeyFile = config.age.secrets.wireguard-pr.path;

    peers = [
      {
        publicKey = "e1npc4hAQkm4BevEdUJ9ABW5L9C3duekoQYtXa3v9SQ=";
        presharedKeyFile = config.age.secrets.wireguard-sh.path;
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "31.207.89.98:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}