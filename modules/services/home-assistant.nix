{ config, pkgs, lib, ... }:

{
  services.home-assistant = {
    enable = true;

    extraComponents = [
      "analytics"
      "default_config"
      "esphome"
      "google_translate"
      "isal"
      "met"
      "radio_browser"
      "rpi_power"
      "shopping_list"
    ];

    config = {
      default_config = {};
      http = {
        server_host = "::1";
        trusted_proxies = [ "::1" ];
        use_x_forwarded_for = true;
      };
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
    };
  };

  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0644 hass hass"
    "f ${config.services.home-assistant.configDir}/scripts.yaml 0644 hass hass"
  ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "home.sh.tomwissing.de" = {
        forceSSL = true;
        quic = true;
        http3 = true;
        useACMEHost = "sh.tomwissing.de";
        extraConfig = ''
          allow 192.168.178.0/24;
          allow 127.0.0.1;
          allow ::1;
          allow fdf9:a758:563::/64;
          allow 2a00:6020:a512:8c00::/64;
          deny all;
        '';
        locations."/" = {
          proxyPass = "http://[::1]:8123";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            add_header Alt-Svc 'h3=":443"; ma=86400';
          '';
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
