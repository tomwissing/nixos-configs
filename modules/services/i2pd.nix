{ config, pkgs, lib, ... }:
{
  services.i2pd = {
    enable = true;
    enableIPv6 = true;
    port = 9111;
    ntcp2.published = true;
    ssu2.published = true;
    bandwidth = 2048;
    proto.http.enable = true;
    proto.httpProxy = {
      enable = true;
      outproxy = "http://exit.stormycloud.i2p/,http://purokishi.i2p";
    };
    precomputation.elgamal = false;
    addressbook.subscriptions = [
      "http://inr.i2p/export/alive-hosts.txt"
      "http://i2p-projekt.i2p/hosts.txt"
      "http://stats.i2p/cgi-bin/newhosts.txt"
      "http://reg.i2p/export/hosts.txt"
    ];   
  };
  networking.firewall.allowedTCPPorts = [ 9111 ];
  networking.firewall.allowedUDPPorts = [ 9111 ];
}
