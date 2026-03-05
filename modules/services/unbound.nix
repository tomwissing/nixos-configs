{ config, pkgs, lib, ... }:

{
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      server = {
        interface =  "127.0.0.1";
        port = 5353;

        serve-expired = "yes";
        serve-expired-client-timeout = 0;
        prefetch = "yes";
      };
    };
  };
}
