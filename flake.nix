{
  description = "NixOS configuration (flake) for stschiff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      # Use the `lib.nixosSystem` from the nixpkgs flake input (guaranteed to exist),
      # and provide `pkgs` (imported with shared config) as a specialArg for modules.
      pkgsForModules = import nixpkgs {
        inherit system;
        config = (import ./nixpkgs-config.nix);
      };
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./configuration.nix ];
          specialArgs = {
            pkgs = pkgsForModules;
          };
        };
      };
    };
}
