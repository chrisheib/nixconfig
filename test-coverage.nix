let
  pkgs = import <nixpkgs> {
    overlays = [ (import /etc/nixos/overlays/plain-pkgs.nix) ];
  };
in
pkgs.python313Packages.coverage
