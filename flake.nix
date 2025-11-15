{
  description = "NixOS configuration (flake) for stschiff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{ self, ... }:
    let
      nixpkgs = inputs.nixpkgs;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # Export a top-level nixosConfigurations so `nixos-rebuild --flake /etc/nixos#nixos` works
      nixosConfigurations = {
        nixos = pkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./configuration.nix ];
          specialArgs = {
            inherit pkgs;
            lib = pkgs.lib;
          };
        };
      };
    };
}
