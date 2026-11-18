{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.adguardhome = {
    enable = true;
  };

  users.users.adguardhome = {
    isSystemUser = true;
    group = "adguardhome";
    extraGroups = [ "acme" ];
  };
  users.groups.adguardhome = { };

  networking.firewall.allowedUDPPorts = [
    53
    853
  ];
  networking.firewall.allowedTCPPorts = [
    53
    853
  ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "dns.sh.tomwissing.de" = {
        forceSSL = true;
        http2 = false;
        http3 = false;
        quic = false;
        useACMEHost = "sh.tomwissing.de";
        locations."/dns-query" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true; # allows live updates if needed
        };
        locations."/" = {
          return = 404;
        };
      };
    };
  };
}
