{
  config,
  pkgs,
  lib,
  pkgsUnstable,
  ...
}:
{
  services.i2pd = {
    enable = true;
    package = pkgsUnstable.i2pd;
    settings = {
      ipv6 = true;
      port = 9111;
      bandwidth = 2048;
      http.enabled = true;
      httpproxy = {
        enabled = true;
        outproxy = "http://exit.stormycloud.i2p/,http://purokishi.i2p";
      };
      precomputation.elgamal = false;
    };
  };
  networking.firewall.allowedTCPPorts = [ 9111 ];
  networking.firewall.allowedUDPPorts = [ 9111 ];
}
