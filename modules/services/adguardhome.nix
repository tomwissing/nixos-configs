{ config, pkgs, lib, ... }:

{
    services.adguardhome = {
      enable = true;
  };
  
  users.users.adguardhome = {
    isSystemUser = true;
    group = "adguardhome";
    extraGroups = ["acme"];
  };
  users.groups.adguardhome = {};

  networking.firewall.allowedUDPPorts = [ 53 853 ];
  networking.firewall.allowedTCPPorts = [ 53 853 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "dns.sh.tomwissing.de" = {
        forceSSL = true;
        quic = true;
        http3 = true;
        useACMEHost = "sh.tomwissing.de";
        locations."/dns-query" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true; # allows live updates if needed
          extraConfig = ''
            add_header Alt-Svc 'h3=":443"; ma=86400';
          '';
        };
        locations."/" = {
          return = 404;
        };
      };
    };
  };
}
