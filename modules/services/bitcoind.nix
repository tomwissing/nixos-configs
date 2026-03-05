{ config, pkgs, lib, ... }:


let
  sam = config.services.i2pd.proto.sam;
in
{
  services.i2pd.proto.sam.enable = true;

  services.bitcoind.main = {
    enable = true;

    prune = 10240;
    dbCache = 4;

    extraConfig =
    ''
      server=1
      maxconnections=8
      blocksonly=1
      bind=[::]
      natpmp=0
    ''
    + lib.optionalString sam.enable ''
        i2psam=${sam.address}:${toString sam.port}
      '';
  };

  networking.firewall.allowedTCPPorts = [ 8333 ];

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
      Nice = 15;
      IOSchedulingClass = "idle";
    };
  };
}
