{ config, lib, pkgs, ... }:

let
  # Every *.pub dropped into secrets/ssh/users/ becomes an authorized key
  # for tom on every host - no list to keep in sync. (Nix flakes only see
  # git-tracked files, so new keys need a `git add`.)
  sshKeysDir = ../secrets/ssh/users;
  authorizedKeyFiles =
    lib.mapAttrsToList (name: _: sshKeysDir + "/${name}")
      (lib.filterAttrs
        (name: type: type == "regular" && lib.hasSuffix ".pub" name)
        (builtins.readDir sshKeysDir));
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Shared user configuration
  users.users.tom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "tom";

    openssh.authorizedKeys.keyFiles = authorizedKeyFiles;
  };

  # Packages common to all machines
  environment.systemPackages = with pkgs; [
    vim
    htop
  ];
}
