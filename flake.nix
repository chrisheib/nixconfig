{
  description = "NixOS configuration (flake) for stschiff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{ self, ... }:
    let
      system = "x86_64-linux";
      nixpkgs = inputs.nixpkgs;
      # Import nixpkgs with the same nixpkgs.config settings you had in configuration.nix
      # so flakes evaluation allows unfree packages and the same permitted insecure packages.
      pkgs = import nixpkgs {
        inherit system;
        config = (import ./nixpkgs-config.nix);
      };
    in
    {
      nixosConfigurations = {
        nixos = pkgs.nixosSystem {
          inherit system;
          modules = [ ./configuration.nix ];
          specialArgs = { inherit pkgs; };
        };
      };
    };
}
