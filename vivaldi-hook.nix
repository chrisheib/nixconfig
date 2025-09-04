{
  pkgs,
  ...
}:
let
  vhooks = pkgs.fetchFromGitHub {
    owner = "justdanpo";
    repo = "VivaldiHooks";
    rev = "master";
    # Replace this value with the sha256 you prefetch (see below)
    # nix-prefetch-url --unpack https://github.com/justdanpo/VivaldiHooks/archive/refs/heads/master.tar.gz
    sha256 = "139pmawzln35s708f14xgsbgi78nydxq7myagc47s970dlpk1f5d";
  };
  myHookJs = ./vivaldi-move-menu-to-right.js; # must live next to this nix file
in
{
  nixpkgs.overlays = [
    (final: prev: {
      vivaldi = prev.vivaldi.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          # copy the VivaldiHooks vivaldi/ folder into resources
          cp -r "${vhooks}/vivaldi" "$out/opt/vivaldi/resources/"
          # ensure hooks dir exists and copy our custom hook
          # mkdir -p "$out/opt/vivaldi/resources/vivaldi/hooks"
          chmod -R +rwx "$out/opt/vivaldi/resources/vivaldi/hooks"
          cp "${myHookJs}" "$out/opt/vivaldi/resources/vivaldi/hooks/move-menu-to-right.js"
          chmod +rwx "$out/opt/vivaldi/resources/vivaldi/hooks/move-menu-to-right.js"
        '';
      });
    })
  ];
}
