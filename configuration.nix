# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}: let
  nix-vscode-extensions = import (builtins.fetchTarball {
    url = "https://github.com/nix-community/nix-vscode-extensions/archive/master.tar.gz";
  });

  my-vscode-no-sandbox = pkgs.vscode-with-extensions.overrideAttrs (oldAttrs: rec {
    postFixup = ''
      ${oldAttrs.postFixup or ""}
        wrapProgram $out/bin/code --add-flags "--no-sandbox"
    '';
  });
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
  ];

  # To switch to unstable nixpgks:
  # sudo nix-channel --list
  # sudo nix-channel --remove nixos
  # sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
  # Or as overlay: https://www.reddit.com/r/NixOS/comments/17v4o9i/comment/k9akqcv

  boot = {
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 5;
    loader.efi.canTouchEfiVariables = true;
    # cachyos: https://www.nyx.chaotic.cx/
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    extraModprobeConfig =
      "options nvidia "
      + lib.concatStringsSep " " [
        # nvidia assume that by default your CPU does not support PAT,
        # but this is effectively never the case in 2023
        "NVreg_UsePageAttributeTable=1"
        # This is sometimes needed for ddc/ci support, see
        # https://www.ddcutil.com/nvidia/
        #
        # Current monitor does not support it, but this is useful for
        # the future
        "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
      ];
    plymouth = {
      enable = true;
    };

    # decrease display time of systemd-boot menu
    loader.timeout = 1;

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];

    kernelModules = ["amdgpu" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # virtualisation.docker.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # services.xserver.enable = true;
  # services.displayManager.defaultSession = "plasmax11";
  programs.xwayland.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [pkgs.brlaser];

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.stschiff = {
    isNormalUser = true;
    description = "stschiff";
    extraGroups = ["networkmanager" "wheel" "libvirtd" "docker"];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;

  programs.starship.enable = true;
  programs.direnv.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      l = "ls";
      ll = "ls";
      nrt = "sudo nixos-rebuild test";
      nrs = "() {up && sudo nh os switch --update --file '<nixpkgs/nixos>' && cur && gcp \"$1\" && gc }";
      nrsu = "sudo nix-channel --update && nrs \"System Update\"";
      nrsb = "nrs \"$1\" && gut";
      nrsrepair = "sudo nixos-rebuild switch --repair";
      gut = "qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot";
      gcp = "() {cd ~/.nixos && git add . && git commit -m \"Generation $(cur): $1\" && git push}";
      cur = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | cut -d \" \" -f 2";
      up = "sudo nix-channel --update && sudo nh os build --update --file '<nixpkgs/nixos>' && nvdnh diff /run/current-system ./result | tee /home/stschiff/.nixos/nixdiff.txt && cat /home/stschiff/.nixos/nixdiff.txt";
      gc = "nh clean all --keep 5 --keep-since 7d";
    };

    histSize = 10001;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
      "INC_APPEND_HISTORY"
      "HIST_REDUCE_BLANKS"
    ];
  };
  # virtualisation.waydroid.enable = true;

  nix.extraOptions = ''
    trusted-users = root stschiff
    experimental-features = nix-command flakes
  '';

  nix.settings = {
    cores = 6;
    max-jobs = 2;
  };

  programs.partition-manager.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    google-fonts
  ];
  fonts.fontDir.enable = true; # https://wiki.nixos.org/wiki/Fonts#Flatpak_applications_can't_find_system_fonts

  # ignore because of global allow unfree
  # nixpkgs.config.allowUnfreePredicate = pkg:
  #   builtins.elem (lib.getName pkg) [
  #     "steam"
  #     "steam-unwrapped"
  #     "steam-original"
  #     "steam-run"
  #   ];

  programs.gamemode.enable = true; # https://wiki.nixos.org/wiki/GameMode

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vdpauinfo # sudo vainfo
      libva-utils # sudo vainfo
      nvidia-vaapi-driver # nvidia-smi dmon
      vaapiVdpau
      # intel-media-driver
      # intel-vaapi-driver
      # intel-media-sdk
    ];
  };

  environment.variables = {
    MOZ_DISABLE_RDD_SANDBOX = "1";
    # LIBVA_DRIVER_NAME = "i965";
    # LIBVA_DRIVER_NAME = "iHD";

    LIBVA_DRIVER_NAME = "nvidia";
    VDPAU_DRIVER = "nvidia";

    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # LIBVA_DRIVER_NAME = "radeonsi";
    # VDPAU_DRIVER = "radeonsi";

    NVD_BACKEND = "direct";
    EGL_PLATFORM = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1";
    MANGOHUD_CONFIG = "fps_limit=140,no_display";
    MANGOHUD = "1";
    KWIN_DRM_USE_EGL_STREAMS = "1"; # Wayland GPU accel

    WEBKIT_DISABLE_DMABUF_RENDERER = "1"; # try to fix orca
    CUDA_TOOLKIT_ROOT_DIR = "${pkgs.cudaPackages.cudatoolkit}";
  };

  # https://wiki.nixos.org/wiki/NVIDIA
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    #  {
    #   version = "570.133.07"; # use new 570 drivers
    #   sha256_64bit = "sha256-LUPmTFgb5e9VTemIixqpADfvbUX1QoTT2dztwI3E3CY="; # "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU="; # .run.drv
    #   openSha256 = "sha256-9l8N83Spj0MccA8+8R1uqiXBS0Ag4JrLPjrU3TaXHnM=";
    #   settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU="; # src.drv
    #   usePersistenced = false;
    # };

    modesetting.enable = lib.mkDefault true;
    # Power management is nearly always required to get nvidia GPUs to
    # behave on suspend, due to firmware bugs.
    powerManagement.enable = true;
    # powerManagement.finegrained = true; # requires offload to be enabled
    open = true; # Set to false for proprietary drivers -> https://download.nvidia.com/XFree86/Linux-x86_64/565.77/README/kernel_open.html
    # prime = {
    # offload.enable = true;
    # offload.enableOffloadCmd = true;

    # intelBusId = "PCI:0:2:0";
    # nvidiaBusId = "PCI:1:0:0";
    # };
    # prime = {
    #   offload.enable = true;
    #   nvidiaBusId = "PCI:1:0:0"; # Adjust based on your hardware
    #   amdgpuBusId = "PCI:0:2:0"; # Adjust based on your hardware
    # };
  };

  hardware.bluetooth = {
    enable = true;
    # settings.General.Experimental = true;
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "stschiff";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # build packages with cuda support
  # nixpkgs.config.cudaSupport = true;

  # https://wiki.nixos.org/wiki/Virt-manager
  # https://sysguides.com/install-a-windows-11-virtual-machine-on-kvm
  # https://www.tomshardware.com/how-to/install-windows-11-without-microsoft-account
  # virtualisation.libvirtd.enable = true;
  # programs.virt-manager.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    (my-vscode-no-sandbox.override {
      vscodeExtensions = with vscode-extensions; [
        tauri-apps.tauri-vscode
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-containers
        jnoortheen.nix-ide
        kamadorueda.alejandra
        rust-lang.rust-analyzer
        usernamehw.errorlens
        tamasfe.even-better-toml
        mkhl.direnv
        thenuprojectcontributors.vscode-nushell-lang
        mechatroner.rainbow-csv
        ms-vscode.cpptools
        redhat.vscode-xml
        github.copilot-chat
        github.copilot
      ];
    })

    # brave
    mullvad-browser
    ungoogled-chromium

    kdePackages.kate # editor with sudo
    thunderbird
    # my-vscode
    # bitwarden

    vesktop # change autostart Exec to: Exec=sleep 5  && vesktop
    teamspeak3
    alsa-utils #amixer
    pamixer

    dolphin-emu
    # lutris # gaming launcher -> added as system package
    # heroic # gaming launcher (epic)
    # libstrangle # frame limiter: steam command: strangle 140 %command%
    # gamescope # https://www.reddit.com/r/HuntShowdown/comments/1hdyetz/comment/m22pkci
    # gamescope -H 1440 -f -b --force-grab-cursor -- %command%
    mangohud

    alacritty # https://alacritty.org/config-alacritty.html
    kitty
    bottom
    starship
    # nushell
    zsh # link .zshrc to ~/.zshrc
    carapace
    tealdeer #tldr
    neofetch
    stow
    devenv
    direnv
    nvd
    stress
    pciutils
    btop
    # warp-terminal
    zellij # ctrl p n for new pane

    p7zip # 7zip
    unrar
    k4dirstat # windirstat clone

    nil # nix lsp
    alejandra # nix formatter

    obsidian
    libreoffice
    pinta # graphic

    # for rustdev: use devenv
    # devenv init
    # -> copy file from ststat
    # devenv shell
    rustup
    python3

    vlc
    streamlink-twitch-gui-bin
    ffmpeg-full

    transmission_4-qt

    prismlauncher # minecraft https://wiki.nixos.org/wiki/Prism_Launcher

    kdePackages.kalk # calculator
    krusader # file manager (like total commander) and ftp
    kde-rounded-corners

    # waydroid # also enable virtualisation.waydroid.enable

    git
    ntfs3g # allow read write ntfs mounts
    # docker-compose
    (lutris.override {
      extraPkgs = pkgs: [
        umu-launcher
      ];
    })
    wineWowPackages.stable
    winetricks

    brlaser # printer

    # Orca segfaults if not run with mesa: https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
    # __GLX_VENDOR_LIBRARY_NAME=mesa __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json orca-slicer
    orca-slicer # broken cuda

    # bambu-studio # broken cuda
    # prusa-slicer # expensive to build o.o
    # unstable.cura # currently broken due to python
    # appimage-run # for cura
    # unstable.cura-appimage

    smartgit #

    webkitgtk_6_0

    # swtpm # tpm emulator for qemu

    # kdePackages.konqueror # for orcaslicer

    # onedrivegui # ist unnötig, siehe onedrive-wiki

    sqlitestudio

    gnome-software # for flatpaks

    lm_sensors
    linuxKernel.packages.linux_xanmod_latest.turbostat

    geekbench

    steam
    protontricks

    variety # wallpaper changer

    firefox-wayland

    adwaita-icon-theme
    gtk3

    minion

    # cudaPackages.cudatoolkit

    rclone
    restic
    restic-browser
    backrest

    nh # nix os helper

    libnotify # enables notify-send

    cava # audio visualizer
  ];

  # Enable GNOME settings manager
  programs.dconf.enable = true;

  programs.steam = {
    enable = true;
    # package = unstable.steam;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true;
  };

  # Install firefox.
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland;
  };

  # https://github.com/TLATER/dotfiles/blob/master/nixos-modules/nvidia/default.nix
  programs.firefox.preferences = {
    "gfx.webrender.all" = true;
    # "gfx.x11-egl.force-enabled" = true;
    "media.av1.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.ffvpx.enabled" = false;
    "media.hardware-video-decoding.enabled" = true;
    "media.hardware-video-decoding.force-enabled" = true;
    "media.rdd-ffmpeg.enabled" = true;
    "media.rdd-vpx.enabled" = true;
    "widget.dmabuf.force-enabled" = true;
  };

  ########## SERVICES ##########

  # Resolve local hostnames via ip4: https://discourse.nixos.org/t/help-with-local-dns-resolution/20305/5
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  services.flatpak.enable = true; # https://wiki.nixos.org/wiki/Flatpak
  services.onedrive.enable = true; # https://wiki.nixos.org/wiki/OneDrive

  services.udev.packages = [
    pkgs.platformio-core # embedded dev
    pkgs.openocd # embedded debugger
    pkgs.dolphin-emu
  ];

  systemd.services.make_cpu_energy_readable = {
    description = "Make energy_uj readable for all users to allow displaying cpu power usage in ststat";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "make_cpu_energy_readable" ''chmod a+r /sys/class/powercap/intel-rapl:0/energy_uj''}";
      # It’s often a good idea to mark the service active after the command finishes.
      RemainAfterExit = true;
    };
  };

  # defaults to port 9898
  systemd.services.backrest = {
    description = "Launch backrest to take care of backups";
    wantedBy = ["multi-user.target"];
    requires = ["network-online.target"];
    script = "backrest";
    path = [pkgs.backrest pkgs.rclone];
    environment = {
      BACKREST_PORT = "0.0.0.0:9898";
    };
    serviceConfig = {
      Type = "simple";
      User = "stschiff";
      # AmbientCapabilities = "CAP_DAC_READ_SEARCH";
      # CapabilityBoundingSet = "CAP_DAC_READ_SEARCH";
      # ExecStart = "backrest";
      # It’s often a good idea to mark the service active after the command finishes.
      # RemainAfterExit = true;
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    # Risk of Rain 2013
    11100
  ];
  networking.firewall.allowedUDPPorts = [
    # Risk of Rain 2013
    11100
  ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
