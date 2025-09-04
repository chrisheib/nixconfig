{
  ...
}:
let
  myHookJs = ./vivaldi-move-menu-to-right.js; # must live next to this nix file
in
{
  nixpkgs.overlays = [
    (final: prev: {
      vivaldi = prev.vivaldi.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          cp "${myHookJs}" "$out/opt/vivaldi/resources/vivaldi/move-menu-to-right.js"
          chmod +rwx "$out/opt/vivaldi/resources/vivaldi/move-menu-to-right.js"
          # insert move menu call into window.html before </body>
          sed -i 's|</body>|<script src="move-menu-to-right.js"></script></body>|' "$out/opt/vivaldi/resources/vivaldi/window.html"
        '';
      });
    })
  ];
}
