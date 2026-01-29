{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
  {
    # NixOS configurations per machine
    nixosConfigurations = {
      wsl = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; } ;
        system = "x86_64-linux";
        modules = [
          inputs.nixos-wsl.nixosModules.default
          agenix.nixosModules.default
          ./hosts/wsl.nix
          ./modules/common.nix
        ];
      };

      rpi3 = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; } ;
        system = "aarch64-linux";
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
        ];
      };
    };
  };
}
