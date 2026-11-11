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

    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      autosuggestions = {
        enable = true;
        strategy = [
          "match_prev_cmd"
          "completion"
        ];
      };
      syntaxHighlighting.enable = true;
    };
  };

  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = [
    pkgs.bitwarden-desktop
    pkgs.libreoffice
    pkgs.mpv

    pkgsUnstable.opencode
    pkgsUnstable.pi-coding-agent
    pkgsUnstable.chatgpt
  ];
}
