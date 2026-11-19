{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.services.powerdevilPowerStates;

  acModeScript = pkgs.writeShellScript "powerdevil-ac-display-mode" ''
    exec ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor \
      ${lib.escapeShellArg "output.${cfg.output}.mode.${cfg.acMode}"}
  '';

  batteryModeScript = pkgs.writeShellScript "powerdevil-battery-display-mode" ''
    exec ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor \
      ${lib.escapeShellArg "output.${cfg.output}.mode.${cfg.batteryMode}"}
  '';
in
{
  options.services.powerdevilPowerStates = {
    enable = mkEnableOption "PowerDevil power profiles and display modes";

    output = mkOption {
      type = types.str;
      default = "eDP-1";
      example = "eDP-1";
      description = "KScreen output connector name to change.";
    };

    acMode = mkOption {
      type = types.str;
      example = "1920x1080@144";
      description = "KScreen mode to use while on AC power.";
    };

    batteryMode = mkOption {
      type = types.str;
      example = "1920x1080@60";
      description = "KScreen mode to use while on battery power.";
    };

    acProfile = mkOption {
      type = types.enum [ "performance" "balanced" "power-saver" ];
      default = "balanced";
      description = "Power profile to use while on AC power.";
    };

    batteryProfile = mkOption {
      type = types.enum [ "performance" "balanced" "power-saver" ];
      default = "power-saver";
      description = "Power profile to use while on battery power.";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."powerdevilrc".text = ''
      [AC][Performance]
      PowerProfile=${cfg.acProfile}

      [AC][RunScript]
      ProfileLoadCommand=${acModeScript}

      [Battery][Performance]
      PowerProfile=${cfg.batteryProfile}

      [Battery][RunScript]
      ProfileLoadCommand=${batteryModeScript}
    '';
  };
}
