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
          # Try common resource locations and install hooks + loader
          for d in \
          "$out/share/vivaldi/resources" \
          "$out/lib/vivaldi/resources" \
          "$out/lib64/vivaldi/resources" \
          "$out/opt/vivaldi/resources"; do
            if [ -d "$d" ]; then
              # copy the VivaldiHooks vivaldi/ folder into resources
              cp -r "${vhooks}/vivaldi" "$d/" || true
              # ensure hooks dir exists and copy our custom hook
              mkdir -p "$d/vivaldi/hooks"
              cp "${myHookJs}" "$d/vivaldi/hooks/move-menu-to-right.js" || true
              # If browser.html exists, back it up and inject jdhooks loader
              if [ -f "$d/vivaldi/browser.html" ]; then
                cp "$d/vivaldi/browser.html" "$d/vivaldi/browser.html.orig" || true
                # Insert loader <script src="vivaldi/jdhooks.js"></script> before bundle.js
                awk 'BEGIN{injected=0} /bundle.js/ && injected==0 { print "<script src=\"vivaldi/jdhooks.js\"></script>"; injected=1 } { print }' \
                  "$d/vivaldi/browser.html" > "$d/vivaldi/browser.html.new" || true
                mv "$d/vivaldi/browser.html.new" "$d/vivaldi/browser.html" || true
              fi
            fi
          done
        '';
      });
    })
  ];
}
