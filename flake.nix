{
  description = "NixOS configuration (flake) for stschiff";

  inputs = {
    nixpkgs.url = "tarball+https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    flake-utils.url = "github:numtide/flake-utils";
    preload-ng.url = "github:miguel-b-p/preload-ng";
  };

  outputs =
    {
      # self,
      preload-ng,
      nixpkgs,
      ...
    }:
    let
      # preconfigured pkgs you want modules to use
      pkgsForModules = import nixpkgs {
        config = (import ./nixpkgs-config.nix);
      };
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {

          # Make pkgsForModules available to modules as an extra arg.
          # Do NOT try to set nixpkgs.pkgs here.
          specialArgs = { inherit pkgsForModules; };

          modules = [
            ./configuration.nix
            preload-ng.nixosModules.default
            {
              services.preload-ng.enable = true;
            }
          ];
        };
      };
    };
}
