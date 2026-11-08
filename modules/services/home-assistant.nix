{ config, pkgs, lib, ... }:

{
  imports = [
    ./home-assistant-solar.nix
    ./home-assistant-home.nix
    ./home-assistant-private.nix
  ];

  services.home-assistant = {
    enable = true;

    extraComponents = [
      "analytics"
      "default_config"
      "esphome"
      "google_translate"
      "growatt_server"
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

      # The classic Growatt API is rate limited. Disable automatic polling in
      # each classic-auth Growatt entry's System options, then refresh each
      # entry every 30 minutes, staggered by 15 minutes. Updating one entity
      # refreshes the coordinator for its whole config entry.
      automation = [
        {
          id = "growatt_classic_poll_sph";
          alias = "Growatt classic polling · SPH";
          description = "Refresh the classic-auth SPH every 30 minutes.";
          trigger = [{
            platform = "time_pattern";
            minutes = "/30";
          }];
          action = [{
            action = "homeassistant.update_entity";
            target.entity_id = "sensor.__growatt_sph_id___pv_gesamtleistung";
          }];
          mode = "single";
        }
        {
          id = "growatt_classic_poll_balkonkraftwerk";
          alias = "Growatt classic polling · Balkonkraftwerk";
          description = "Refresh the classic-auth Balkonkraftwerk every 30 minutes, offset from the SPH.";
          trigger = [{
            platform = "time_pattern";
            minutes = "/15";
          }];
          condition = [{
            condition = "template";
            value_template = "{{ now().minute in [15, 45] }}";
          }];
          action = [{
            action = "homeassistant.update_entity";
            target.entity_id = "sensor.balkonkraftwerk_total_ausgangsleistung";
          }];
          mode = "single";
        }
      ];
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
