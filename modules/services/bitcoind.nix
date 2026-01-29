{ config, pkgs, lib, ... }:

{
  services.bitcoind.main = {
    enable = true;

    prune = 5500;
    dbCache = 175;

    extraConfig = ''
      server=1
      txindex=0
      maxconnections=20
      blocksonly=1
    '';
  };

  # timer to start bitcoind unit after a delay
  systemd.timers.bitcoind-main = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      RandomizedDelaySec = "10min";
Persistent = true;
      Unit = "bitcoind-main.service";
    };
  };

  systemd.services.bitcoind-main = {
    # disable wanted by multiusertarger
    wantedBy = [];
    serviceConfig = {
      Nice = 10;
IOSchedulingClass = "idle";
    };
  };
  }
