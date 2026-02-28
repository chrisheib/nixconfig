self: super: {
  steam = super.steam.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]);
    postInstall = ''
      ${old.postInstall or ""}
      if [ -f "$out/share/applications/steam.desktop" ]; then
        substituteInPlace "$out/share/applications/steam.desktop" \
          --replace-fail \
          "$(grep '^Exec=' "$out/share/applications/steam.desktop")" \
          "Exec=steam %U" || true
      fi
    '';
  });
}
