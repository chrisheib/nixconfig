FROM nixos/nix:latest

RUN printf '%s\n' \
  'experimental-features = nix-command flakes' \
  'system-features = nixos-test benchmark big-parallel kvm' \
  'system-features = gccarch-znver5' \
  > /etc/nix/nix.conf

# Pin nixpkgs explicitly (replace rev/sha256 with whatever you want)
ARG NIXPKGS_URL=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz

RUN nix-build -E 'let nixpkgs = fetchTarball "'"$NIXPKGS_URL"'"; pkgs = import nixpkgs {localSystem = {system = "x86_64-linux"; gcc.arch = "znver5";};   };  in    pkgs.assimp'