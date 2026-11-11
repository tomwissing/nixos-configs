{
  config,
  pkgs,
  lib,
  ...
}:

let
  paperlessUser = config.services.paperless.user;
  consumptionDir = config.services.paperless.consumptionDir;
in
{
  services.paperless = {
    enable = true;
    settings = {
      PAPERLESS_CONSUMER_POLLING = 60;
    };
  };
  fileSystems."${consumptionDir}" = {
    device = "//192.168.178.1/fritz.nas/paperless";
    fsType = "cifs";
    options = [
      "rw"
      "username=scanner"
      "password=scanner#"
      "iocharset=utf8"
      "uid=${toString paperlessUser}"
      "gid=${toString paperlessUser}"
      "nofail"
      "vers=3.0"
      "noserverino"
    ];
  };
}
