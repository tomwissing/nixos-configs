{ config, pkgs, lib, ... }:


let
  sam = config.services.i2pd.proto.sam;
in
{
  services.i2pd.proto.sam.enable = true;

  services.bitcoind.main = {
    enable = true;

    prune = 5500;
    dbCache = 96;

    extraConfig =
    ''
      server=1
      txindex=0
      maxconnections=16
      assumevalid=00000000000000000000df86ba53f196c6fc1737ef9845c21be57c2a11f00375
      blocksonly=1
      bind=[::]
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
