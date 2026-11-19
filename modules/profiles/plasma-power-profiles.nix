{ ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";

  home-manager.users.tom = {
    home.stateVersion = "26.05";
    imports = [ ../home-manager/powerdevil-power-states.nix ];
    services.powerdevilPowerStates = {
      enable = true;
      output = "eDP-1";
      acMode = "1920x1080@144";
      batteryMode = "1920x1080@60";
      acProfile = "balanced";
      batteryProfile = "power-saver";
    };
  };
}
