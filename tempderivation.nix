{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.13.7";
  pname = "Exiled-Exchange-2";

  src = fetchurl {
    url = "https://github.com/Kvan7/Exiled-Exchange-2/releases/download/v${version}/Exiled-Exchange-2-${version}.AppImage";
    hash = "sha256-IJ8nzJvpyAKhUb+QNGmsPLYP50+ARJlaXivaGYKTgj8=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 rec {
  inherit pname version src;
  extraInstallCommands = ''
    mkdir -p "$out/share/applications"

    # Copy any extracted hicolor icons from the AppImage extraction output for the desktop file
    if [ -d "${appimageContents}/usr/share/icons/hicolor" ]; then
      find "${appimageContents}/usr/share/icons/hicolor" -type f -name "exiled-exchange-2.png" | while read -r f; do
        rel=$(printf '%s' "$f" | sed -e "s|^${appimageContents}/usr/share/icons/hicolor/||")
        dir=$(dirname "$rel")
        mkdir -p "$out/share/icons/hicolor/$dir"
        install -m 644 "$f" "$out/share/icons/hicolor/$rel"
      done
    fi

    # Create a .desktop file to integrate with desktop environments
    printf "%s\n" \
      "[Desktop Entry]" \
      "Type=Application" \
      "Name=Exiled Exchange 2" \
      "Exec=${pname}" \
      "Icon=exiled-exchange-2" \
      "Categories=Game;" \
      > "$out/share/applications/${pname}.desktop"
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
