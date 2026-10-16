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

## ffmpeg fix movie

ffmpeg -i input.mp4 -c:v copy -c:a aac -b:a 192k fixed.mp4


## Slow KDE workaround

https://github.com/NixOS/nixpkgs/issues/363068#issuecomment-5209282821

```
mkdir -p ~/.local/share/plasma/desktoptheme/default/translucent
touch ~/.local/share/plasma/desktoptheme/default/translucent/colors
```

## Burn ISO to USB:
sudo fdisk -l
sudo dd bs=4M if=Downloads/Win11_25H2_German_x64_v2.iso of=/dev/sdX status=progress oflag=sync


## Steam Launch Options for modded launchers
sed 's/Terraria\.exe/TerrariaInjector.exe/' <<< "%command%" | sh


## Burn movie to dvd
ffmpeg -i input_av1.mkv -target pal-dvd -aspect 16:9 output.mpg
dvdauthor -o dvd_fs -t output.mpg
dvdauthor -o dvd_fs -T
genisoimage -dvd-video -o movie_pal.iso dvd_fs
growisofs -dvd-compat -Z /dev/sr0=movie_pal.iso
