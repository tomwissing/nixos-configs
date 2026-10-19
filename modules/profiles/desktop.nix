{ pkgs, pkgsUnstable, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;
    # policies = { };
  };

  environment.systemPackages = [
    pkgs.bitwarden-desktop
    pkgs.libreoffice
    pkgs.mpv

    pkgsUnstable.opencode
    pkgsUnstable.pi-coding-agent
  ];
}
