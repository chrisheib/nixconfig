{ config, pkgs, ... }:
{
  # boot.kernelPackages = pkgs.linuxPackages_6_10; 

  programs.bash.shellAliases = {
    l = "ls -alh";
    ll = "ls -l";
    ls = "ls --color=tty";
    nrs = "sudo nixos-rebuild switch -I nixos-config=/home/schiff/nixconfig/configuration.nix && cur";
    nrsrepair = "sudo nixos-rebuild switch --repair -I nixos-config=/home/schiff/nixconfig/configuration.nix";
    nrsu = "sudo nix-channel --update && nrs";
    nrsb = "nrs && reboot";
    cur = "echo 'Current Generation: ' && sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'";
  };

  boot.kernelModules = ["88XXau"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    rtl88xxau-aircrack
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget  
  environment.systemPackages = with pkgs; [
    git
    chromium
    usbutils    
    lshw
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        jnoortheen.nix-ide
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "0.47.2";
          sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        }
      ];
    })
  ];
}
