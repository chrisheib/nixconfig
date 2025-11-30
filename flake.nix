{
  description = "NixOS configuration (flake) for stschiff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs =
    {
      # self,
      nixpkgs,
      chaotic,
      ...
    }:
    let
      system = "x86_64-linux";

      # preconfigured pkgs you want modules to use
      pkgsForModules = import nixpkgs {
        inherit system;
        config = (import ./nixpkgs-config.nix);
      };
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;

          # Make pkgsForModules available to modules as an extra arg.
          # Do NOT try to set nixpkgs.pkgs here.
          specialArgs = { inherit pkgsForModules chaotic; };

          modules = [
            chaotic.nixosModules.default
            ./configuration.nix
          ];
        };
      };
    };
}
