{
  description = "NixOS configuration (flake) for stschiff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{ }:
    let
      nixpkgs = inputs.nixpkgs;
      flakeUtils = inputs."flake-utils";
    in
    flakeUtils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
      in
      {
        nixosConfigurations = {
          # key matches the hostname in your configuration.nix (networking.hostName)
          nixos = pkgs.lib.nixosSystem {
            inherit system;
            modules = [
              ./configuration.nix
            ];
            # make pkgs and lib available as special args to modules
            specialArgs = { inherit pkgs lib; };
          };
        };
      }
    );
}
