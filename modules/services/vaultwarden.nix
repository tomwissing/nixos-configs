{
  config,
  pkgs,
  lib,
  ...
}:

{
  age.secrets.vaultwarden.file = ../../secrets/vaultwarden.age;

  services.vaultwarden = {
    enable = true;
    backupDir = "/var/local/vaultwarden/backup";
    # in order to avoid having  ADMIN_TOKEN in the nix store it can be also set with the help of an environment file
    # be aware that this file must be created by hand (or via secrets management like sops)
    environmentFile = config.age.secrets.vaultwarden.path;

    config = {
      # Refer to https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
      # DOMAIN = "https://bitwarden.example.com";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
    };
  };

  services.nginx = {
    virtualHosts = {
      "warden.sh.tomwissing.de" = {
        forceSSL = true;
        quic = true;
        http3 = true;
        useACMEHost = "sh.tomwissing.de";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8222";
          proxyWebsockets = true; # allows live updates if needed
          extraConfig = ''
            
                        add_header Alt-Svc 'h3=":443"; ma=86400';
          '';
        };
      };
    };
  };
}
