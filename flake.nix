{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Pinned: nixos-unstable-small has broken opencode 2.2.5 FOD hash
    # (NixOS/nixpkgs#582673, fix PR #582675 unmerged). 91230cf is the
    # first parent of the breaking merge f12bf47 (opencode 2.2.1, bun 1.4.2,
    # cached). Revert to branch after the fix lands.
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/91230cf4a7d7f0f6c5d98b1bc69396fd3981a5dd";

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
      };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, agenix, ... } @inputs:
  let
    pkgsUnstableFor = system: import inputs.nixpkgs-unstable-small {
      inherit system;
      config.allowUnfree = true;
    };
    mkSpecialArgs = system: {
      pkgsUnstable = pkgsUnstableFor system;
      inherit inputs;
    };
  in
  {
    # NixOS configurations per machine
    nixosConfigurations = {
      wsl = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = mkSpecialArgs system;
        modules = [
          inputs.nixos-wsl.nixosModules.default
          agenix.nixosModules.default
          ./hosts/wsl.nix
          ./modules/common.nix
        ];
      };

      rpi3 = let
        system = "aarch64-linux";
      in nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = mkSpecialArgs system;
        modules = [
          agenix.nixosModules.default
          ./hosts/rpi3/rpi3.nix
          ./modules/common.nix
          ./modules/services/miniflux.nix
          # ./modules/services/adguardhome.nix
          # ./modules/services/unbound.nix
          ./modules/services/i2pd.nix
          ./modules/services/vaultwarden.nix
          ./modules/services/bitcoind.nix
          ./modules/services/home-assistant.nix
          # ./modules/services/qbittorrent-nox.nix
        ];
      };

      msi-thin-gf63-12vf = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = mkSpecialArgs system;
        modules = [
          inputs.disko.nixosModules.default
          agenix.nixosModules.default
          ./hosts/msi-thin-gf63-12vf/msi-thin-gf63-12vf.nix
          ./modules/profiles/desktop.nix
          ./modules/common.nix
        ];
      };

      # Acer Aspire Switch 10 E SW3-013 (Bay Trail tablet, 32-bit UEFI).
      # Built and deployed from this machine - the tablet never builds.
      switch10e = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = mkSpecialArgs system;
        modules = [
          inputs.disko.nixosModules.default
          agenix.nixosModules.default
          ./hosts/switch10e/switch10e.nix
          ./modules/common.nix
        ];
      };

      # Live installer for the Acer Aspire Switch 10 E SW3-013
      # (32-bit UEFI, so the image must be booted by i386-efi GRUB).
      #   nix build .#nixosConfigurations.switch10e-iso.config.system.build.isoImage
      switch10e-iso = let
        system = "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = mkSpecialArgs system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./hosts/switch10e/iso.nix
          # Gives the live session the `tom` user with our SSH keys, plus
          # flakes/nix-command for running nixos-install over ssh.
          ./modules/common.nix
        ];
      };
    };
  };
}
