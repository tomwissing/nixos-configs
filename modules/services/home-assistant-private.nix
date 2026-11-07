{ config, lib, pkgs, ... }:

let
  cfg = config.services.home-assistant;
in
{
  # Keep exact entity identifiers in an encrypted mapping, without requiring
  # secret keys during flake evaluation or builds on the MSI.
  age.secrets.home-assistant-identifiers = {
    file = ../../secrets/home-assistant-identifiers.age;
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  services.home-assistant = {
    configWritable = true;
    lovelaceConfigWritable = true;
  };

  systemd.services.home-assistant = {
    # These templates are copied/rendered at startup too. Changes to either
    # their contents or the encrypted mapping must refresh the runtime files.
    reloadTriggers = [
      config.age.secrets.home-assistant-identifiers.file
      config.environment.etc."home-assistant/dashboard-waermepumpe.yaml".source
      config.environment.etc."home-assistant/dashboard-zuhause.yaml".source
    ];
    preStart = lib.mkMerge [
      (lib.mkBefore ''
        # Migration from the module's previous read-only configuration link.
        if test -L ${lib.escapeShellArg "${cfg.configDir}/configuration.yaml"}; then
          rm -- ${lib.escapeShellArg "${cfg.configDir}/configuration.yaml"}
        fi
      '')
      (lib.mkAfter ''
        ${pkgs.python3}/bin/python3 ${./home-assistant-render-identifiers.py} \
          --mapping ${lib.escapeShellArg config.age.secrets.home-assistant-identifiers.path} \
          --config-dir ${lib.escapeShellArg cfg.configDir}
      '')
    ];
  };
}
