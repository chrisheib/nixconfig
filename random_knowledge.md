## Adding Wireguard Connection

nmcli connection import type wireguard file Downloads/protonvpn.conf

## Starting virtuald network

sudo virsh net-start default

## Helldivers 2:

/home/stschiff/.local/share/Steam/steamapps/common/Helldivers 2/bin/GameGuard löschen
(läuft mit protonge-10-21)

## Nixpkgs PR Tracker

https://nixpkgs-tracker.ocfox.me/?pr=479797

## Filter ANSI Terminal Control Characters

nix-shell -p ansifilter
command | ansifilter > log.txt

## ffmpeg m4a/m4b to mp3

ffmpeg -v warning -fflags +discardcorrupt+genpts -err_detect ignore_err -i source.m4b -c:a libmp3lame -q:a 2 target.mp3
