{ config, pkgs, lib, ... }:

{
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      server = {
        interface =  "127.0.0.1";
        port = 5353;
      };
    };
  };
}
