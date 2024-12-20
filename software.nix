{
  config,
  pkgs,
  ...
}: {
  # boot.kernelPackages = pkgs.linuxPackages_6_10;
  # boot.kernelPackages = pkgs.linuxPackages_6_9;
  boot.kernelPackages = pkgs.linuxPackages_xanmod_stable;

  programs.bash.shellAliases = {
    l = "ls -alh";
    ll = "ls -l";
    ls = "ls --color=tty";
    nrt = "sudo nixos-rebuild test -I nixos-config=/home/schiff/nixconfig/configuration.nix && cur && gcp";
    nrs = "sudo nixos-rebuild switch -I nixos-config=/home/schiff/nixconfig/configuration.nix && cur && gcp";
    nrsrepair = "sudo nixos-rebuild switch --repair -I nixos-config=/home/schiff/nixconfig/configuration.nix";
    nrsu = "sudo nix-channel --update && nrs";
    nrsb = "nrs && gut";
    cur = "sudo echo -n 'Current Generation: ' && sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'";
    gut = "qdbus org.kde.Shutdown /Shutdown  org.kde.Shutdown.logoutAndReboot";
    gcp = "(cd ~/nixconfig && git add . && git commit -m \"Generation $(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')\" && git push)";
  };

  boot.kernelModules = ["88XXau"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    rtl88xxau-aircrack
  ];

  programs.kdeconnect.enable = true;
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nvtopPackages.intel # nvtop
    git
    # firefox-vaapi
    libva-utils
    google-chrome
    vdpauinfo # sudo vainfo
    nil # nix lsp
    alejandra # nix formatter
    # nvidia-smi
    (chromium.override {
      commandLineArgs = [
        "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks"
        "--disable-features=UseChromeOSDirectVideoDecoder,Vulkan"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--enable-gpu-rasterization"
      ];
    })
    usbutils
    lshw
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions;
        [
          bbenoist.nix
          ms-python.python
          ms-azuretools.vscode-docker
          ms-vscode-remote.remote-ssh
          jnoortheen.nix-ide
          kamadorueda.alejandra
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
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
