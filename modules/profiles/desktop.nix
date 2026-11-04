{ pkgs, pkgsUnstable, ... }:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  programs = {
    firefox = {
      enable = true;
      package = pkgs.firefox-esr;
      # policies = { };
    };
    gnupg.agent.enable = true;
  };
  

  environment.systemPackages = [
    pkgs.bitwarden-desktop
    pkgs.libreoffice
    pkgs.mpv

    pkgsUnstable.opencode
    pkgsUnstable.pi-coding-agent
  ];
}
