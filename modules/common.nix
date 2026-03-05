{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Shared user configuration
  users.users.tom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "tom";

    openssh.authorizedKeys.keyFiles = [
      ../secrets/ssh/users/tom-wsl.pub
      ../secrets/ssh/users/tom-win.pub
      ../secrets/ssh/users/tom-zorn.pub
      ../secrets/ssh/users/tom-iphone17.pub
    ];
  };

  # Packages common to all machines
  environment.systemPackages = with pkgs; [
    vim
    htop
  ];
}
