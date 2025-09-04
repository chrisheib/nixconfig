{
  nixpkgs.overlays = [
    (
      self: super:
      let
        widevine = super.widevine-cdm;
      in
      {
        ungoogled-chromium = super.ungoogled-chromium.overrideAttrs (oldAttrs: {
          # ensure we reference widevine so it becomes a dependency
          buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ widevine ];
          postInstall = ''
            ${oldAttrs.postInstall or ""}
            mkdir -p $out/share/ungoogled-chromium
            # copy any WidevineCdm* directory from the widevine package
            cp -R "${widevine}/WidevineCdm" "$out/share/ungoogled-chromium/WidevineCdm/4.10.2891.0"

            # create the "latest" pointer file Chromium expects
            printf '{"Path":"%s"}\n' "$out/share/ungoogled-chromium/WidevineCdm/4.10.2891.0" > $out/share/ungoogled-chromium/latest-component-updated-widevine-cdm
          '';
        });
      }
    )
  ];
}
