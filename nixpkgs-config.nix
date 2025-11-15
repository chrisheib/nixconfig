{
  # Shared nixpkgs import-time configuration used by both flake evaluation
  # and the NixOS module system. Keep options affecting package evaluation
  # here (allowUnfree, permittedInsecurePackages, overlays, etc.).

  # Allow unfree packages (was set in configuration.nix before)
  allowUnfree = true;

  # Packages that are allowed to be treated as insecure (as in your config)
  permittedInsecurePackages = [
    "gradle-7.6.6"
  ];

  # If you use overlays, add them here. Put overlay expressions (final: prev: {...})
  # overlays = [ (final: prev: { /* ... */ }) ];

}
