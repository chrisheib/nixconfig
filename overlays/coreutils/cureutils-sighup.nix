final: prev: {
  coreutils = prev.coreutils.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./tests-notty-sighup.patch
    ];
  });
}
