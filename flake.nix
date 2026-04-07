{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
      };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
  };

  outputs = { self, nixpkgs, agenix, ... } @inputs:
  let
    pkgsUnstableFor = system: import inputs.nixpkgs-unstable-small { inherit system; };
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
          ./modules/services/adguardhome.nix
          ./modules/services/unbound.nix
          ./modules/services/i2pd.nix
          ./modules/services/vaultwarden.nix
          ./modules/services/bitcoind.nix
          # ./modules/services/qbittorrent-nox.nix
        ];
      };
    };
  };
}
