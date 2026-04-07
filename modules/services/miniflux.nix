{ config, pkgs, lib, ... }:

{
  age.secrets.miniflux.file = ../../secrets/miniflux.age;
  age.secrets.cloudflare-dns.file = ../../secrets/cloudflare-dns.age;
  age.secrets.acme-email.file = ../../secrets/acme-email.age;

  services.miniflux = {
    enable = true;
    config = {
      CREATE_ADMIN = 1;
      POLLING_SCHEDULER = "entry_frequency";
      POLLING_FREQUENCY = 30;
      SCHEDULER_ENTRY_FREQUENCY_FACTOR = "1.5";
      BATCH_SIZE = 20;
      WORKER_POOL_SIZE = 4;
      POLLING_LIMIT_PER_HOST = 5;
      DATABASE_MAX_CONNS = 5;
      LOG_LEVEL = "error";
      CLEANUP_FREQUENCY_HOURS = 48;

      FETCHER_ALLOW_PRIVATE_NETWORKS=1;
    };
    adminCredentialsFile = config.age.secrets.miniflux.path;
  };

  services.nginx = {
    enable = true;
    
    # Use nginx with QUIC/HTTP3 support
    # package = pkgs.nginxQuic;

    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;

    appendHttpConfig = ''
      access_log off;
    '';
    
    virtualHosts = {
      "_default" = {
        default = true;
        locations."/" = {
          return = 444;
        };
      };
      "rss.sh.tomwissing.de" = {
        forceSSL = true;
        quic = true;
        http3 = true;
        useACMEHost = "sh.tomwissing.de";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true; # allows live updates if needed
          extraConfig = ''
            add_header Alt-Svc 'h3=":443"; ma=86400';
          '';
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];


  security.acme = {
    acceptTerms = true;
    defaults.profile = "shortlived";
    certs."sh.tomwissing.de" = {
      email = "noreply@tomwissing.de";
      domain = "*.sh.tomwissing.de";
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns.path;
    };
  };
  users.users.nginx.extraGroups = ["acme"];
}
