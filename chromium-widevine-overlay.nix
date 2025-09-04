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
          proprietaryCodecs = true;
          enableWidevine = true;
          # share/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so
          postInstall = ''
            ${oldAttrs.postInstall or ""}
            cp ${widevine}/share/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so $out/share/chromium/libwidevinecdm.so
            # mkdir -p $out/share/chromium
            # copy any WidevineCdm* directory from the widevine package
            # cp -R "${widevine}/WidevineCdm" "$out/share/chromium/WidevineCdm/4.10.2891.0"

            # create the "latest" pointer file Chromium expects
            # printf '{"Path":"%s"}\n' "$out/share/chromium/WidevineCdm/4.10.2891.0" > $out/share/chromium/latest-component-updated-widevine-cdm
          '';
        });
      }
    )
  ];
}
