{
  description = "NixOS configuration (flake) for stschiff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Local nixpkgs checkout containing the `kurve` package.
    # localkurve.url = "path:/home/stschiff/projects/nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      # localkurve,
      ...
    }:
    let
      system = "x86_64-linux";
      # Use the `lib.nixosSystem` from the nixpkgs flake input (guaranteed to exist),
      # and provide `pkgs` (imported with shared config) as a specialArg for modules.
      pkgsForModules = import nixpkgs {
        inherit system;
        config = (import ./nixpkgs-config.nix);
        # Add an overlay that pulls the kurve package from the local checkout
        # overlays = [
        #   (
        #     final: prev:
        #     let
        #       pythonPkgs = prev.python3Packages;
        #     in
        #     {
        #       kurve = prev.callPackage ("${localkurve}/pkgs/by-name/ku/kurve/package.nix") { };
        #       python3Packages = pythonPkgs // {
        #         proton-core = pythonPkgs.proton-core.overrideAttrs (old: {
        #           doCheck = false;
        #         });
        #       };
        #     }
        #   )
        # ];
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
