#!/bin/sh

for f in "$@"; do
    [ -f "$f" ] || continue

    dir="$(dirname "$f")"
    name="$(basename "$f")"

    case "$name" in
        *.tar.gz) base="${name%.tar.gz}" ;;
        *.tgz) base="${name%.tgz}" ;;
        *.tar.bz2) base="${name%.tar.bz2}" ;;
        *.tbz2) base="${name%.tbz2}" ;;
        *.tar.xz) base="${name%.tar.xz}" ;;
        *.txz) base="${name%.txz}" ;;
        *.tar.zst) base="${name%.tar.zst}" ;;
        *.tzst) base="${name%.tzst}" ;;
        *.tar) base="${name%.tar}" ;;
        *.zip) base="${name%.zip}" ;;
        *.7z) base="${name%.7z}" ;;
        *.rar) base="${name%.rar}" ;;
        *.gz) base="${name%.gz}" ;;
        *.bz2) base="${name%.bz2}" ;;
        *.xz) base="${name%.xz}" ;;
        *.zst) base="${name%.zst}" ;;
        *) base="${name%.*}" ;;
    esac

    out="$dir/$base"
    mkdir -p "$out"

    case "$name" in
        *.rar)
            unrar x -o+ -- "$f" "$out/"
            ;;
        *.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst|*.tzst)
            7z x -so -- "$f" | 7z x -si -ttar -o"$out" -y
            ;;
        *)
            7z x -- "$f" -o"$out" -y
            ;;
    esac
done
