{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kdePackages,
}:

stdenvNoCC.mkDerivation {
  pname = "shutdown_or_switch";
  version = "unstable-2025-09-29";

  src = fetchFromGitHub {
    owner = "Davide-sd";
    repo = "shutdown_or_switch";
    rev = "master";
    sha256 = "sha256-NbZyQu23gr0O1QHbhLbcaTXV6t639akW9PF0Jq4Sc3Y=";
  };

  installPhase = ''
    mkdir -p $out/share/plasma/plasmoids/
    cp -r $src/package $out/share/plasma/plasmoids/org.kde.plasma.shutdownorswitch
  '';

  meta = with lib; {
    homepage = "https://github.com/Davide-sd/shutdown_or_switch";
    description = "KDE Plasma widget to quickly access the shutdown options or switch user.";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ Svenum ];
    inherit (kdePackages.kwindowsystem.meta) platforms;
  };
}
