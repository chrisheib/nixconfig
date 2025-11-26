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

  # appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  # extraInstallCommands = ''
  #   substituteInPlace $out/share/applications/${pname}.desktop \
  #     --replace-fail 'Exec=AppRun' 'Exec=${meta.mainProgram}'
  # '';

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
