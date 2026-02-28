self: super: {
  steam = super.steam.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.gnused ];
    postInstall = ''
      ${old.postInstall or ""}
      # Rewrite Exec line in desktop file so it uses the wrapper from PATH
      if [ -f "$out/share/applications/steam.desktop" ]; then
        ${super.gnused}/bin/sed -i 's|^Exec=.*|Exec=steam %U|' "$out/share/applications/steam.desktop" || true
      fi
    '';
  });
}
