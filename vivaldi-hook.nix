{
  ...
}:

{
  # Add an overlay to modify the vivaldi derivation at eval time.
  # Expect the JS file to be next to this module: move-menu-to-right.js
  nixpkgs.overlays = [
    (
      final: prev:
      let
        js = ./vivaldi-move-menu-left-to-right.js;
      in
      {
        # Override the vivaldi derivation to install our hook file
        vivaldi = prev.vivaldi.overrideAttrs (oldAttrs: {
          postInstall = (oldAttrs.postInstall or "") + ''
            # Try common resource locations and copy hook into resources/vivaldi/hooks
            for d in \
              "$out/share/vivaldi/resources" \
              "$out/lib/vivaldi/resources" \
              "$out/lib64/vivaldi/resources" \
              "$out/opt/vivaldi/resources"; do
              if [ -d "$d" ]; then
                mkdir -p "$d/vivaldi/hooks"
                cp "${js}" "$d/vivaldi/hooks/move-menu-to-right.js" || true
              fi
            done

            # Fallback: ensure at least one path exists
            mkdir -p "$out/share/vivaldi/resources/vivaldi/hooks"
            cp "${js}" "$out/share/vivaldi/resources/vivaldi/hooks/move-menu-to-right.js" || true
          '';
        });
      }
    )
  ];
}
