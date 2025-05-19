# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install

alias l='ls'
alias ll='ls'
alias nrt='sudo nixos-rebuild test'
alias nrs='up; sudo nixos-rebuild switch; cur; gcp "$1"; gc'
alias nrsu='sudo nix-channel --update; nrs "System Update"'
alias nrsb='nrs "$1"; gut'
alias nrsrepair='sudo nixos-rebuild switch --repair'
alias gut='qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot'
alias gcp='cd ~/.nixos; git add .; git commit -m "Generation (cur): $1"; git push'
alias cur='sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk "{print \$2}"'
alias up='sudo nix-channel --update; nixos-rebuild build --upgrade; nvd diff /run/current-system ./result | tee /home/stschiff/.nixos/nixdiff.txt; cat /home/stschiff/.nixos/nixdiff.txt'
alias gc='nix-collect-garbage --delete-older-than 7d'