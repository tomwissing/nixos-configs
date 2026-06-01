{ config, lib, pkgs, modulesPath, inputs, ... }:

  
{
  networking.hostName = "wsl";

  boot.binfmt.emulatedSystems = ["aarch64-linux"];
  nix.settings.extra-platforms = config.boot.binfmt.emulatedSystems;

  wsl.enable = true;
  wsl.defaultUser = "tom";
  wsl.useWindowsDriver = true;

   users.users.tom = {
    packages = with pkgs; [
      fastfetchMinimal
      git
    ];
   };

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.x86_64-linux.default
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
    htop
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
