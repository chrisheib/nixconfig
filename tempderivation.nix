{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.12.8";
  pname = "Exiled-Exchange-2";

  src = fetchurl {
    url = "https://github.com/Kvan7/Exiled-Exchange-2/releases/download/v${version}/Exiled-Exchange-2-${version}.AppImage";
    hash = "sha256-hGUmwyhFsM+8XTrFCuaLVYAA85jwrKCftkQ/wlViRHI=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 rec {
  inherit pname version src;
  extraInstallCommands = ''
    # Find a .desktop file produced by the AppImage wrapper and patch its Exec line.
    desktopPath=$(find "$out" -type f -name '*.desktop' | head -n1 || true)
    if [ -n "$desktopPath" ]; then
      substituteInPlace "$desktopPath" --replace-fail 'Exec=AppRun' "Exec=${pname}"
    else
      # If no desktop file exists, create a minimal one so the package is discoverable.
      mkdir -p "$out/share/applications"
      mkdir -p "$out/share/icons/hicolor/1024x1024/apps"

      # Copy any extracted hicolor icons from the AppImage extraction output
      # into $out so the icon name is resolvable by desktop environments.
      if [ -d "${appimageContents}/usr/share/icons/hicolor" ]; then
        find "${appimageContents}/usr/share/icons/hicolor" -type f -name "exiled-exchange-2.png" | while read -r f; do
          rel=$(printf '%s' "$f" | sed -e "s|^${appimageContents}/usr/share/icons/hicolor/||")
          dir=$(dirname "$rel")
          mkdir -p "$out/share/icons/hicolor/$dir"
          install -m 644 "$f" "$out/share/icons/hicolor/$rel"
        done
      fi

      # Create a simple desktop file referring to the icon by name.
      printf "%s\n" \
        "[Desktop Entry]" \
        "Type=Application" \
        "Name=Exiled Exchange 2" \
        "Exec=${pname}" \
        "Icon=exiled-exchange-2" \
        "Categories=Game;" \
        > "$out/share/applications/${pname}.desktop"
    fi
  '';

  meta = {
    description = "Path of Exile 2 trading app for price checking";
    homepage = "https://kvan7.github.io/Exiled-Exchange-2/quick-start";
    downloadPage = "https://github.com/Kvan7/Exiled-Exchange-2/releases";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ chrisheib ];
    platforms = [ "x86_64-linux" ];
  };
}
