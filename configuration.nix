# Currently using: AMD 9950X3D + MSI X670E Gaming Plus WIFI + MSI 3080 TI + 64 GB DDR 5 + NVMe SSDs
{
  config,
  pkgs,
  lib,
  ...
}:
let
  my-vscode-no-sandbox = pkgs.vscode-with-extensions.overrideAttrs (oldAttrs: {
    postFixup = ''
      ${oldAttrs.postFixup or ""}
        wrapProgram $out/bin/code --add-flags "--no-sandbox"
    '';
  });
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./orca.nix
  ];

  nixpkgs = {
    # Load shared import-time config so flakes and the module system agree.
    config = import ./nixpkgs-config.nix;
    overlays = [
      # (import /etc/nixos/overlays/plain-pkgs.nix)
      (import ./overlays/ccache.nix config)
      (import ./overlays/steam-desktop.nix)
      (import ./overlays/plasma-workspace.nix)
    ];
  };

  # nixpkgs.config.packageOverrides = pkgs: {
  #   freetype = pkgs.freetype.overrideAttrs (old: {
  #     patches = (old.patches or [ ]) ++ [
  #       (pkgs.fetchpatch {
  #         url = "https://aur.archlinux.org/cgit/aur.git/plain/0004-QD-OLED-subpixel.patch?h=freetype2-qdoled";
  #         hash = "sha256-XXXXXXX"; # you need to fill this
  #       })
  #     ];
  #   });
  # };

  # To switch to unstable nixpgks:
  # sudo nix-channel --list
  # sudo nix-channel --remove nixos
  # sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
  # sudo nix-channel --add https://nixos.org/channels/nixos-unstable-small nixos
  # Or as overlay: https://www.reddit.com/r/NixOS/comments/17v4o9i/comment/k9akqcv

  boot = {
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 5;
    loader.efi.canTouchEfiVariables = true;
    # cachyos: https://www.nyx.chaotic.cx/
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    # kernelPackages = pkgs.linuxPackages_cachyos-lto;
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

        # Enable Resizable BAR support
        # Check reBar (look for BAR 1 > 1GB):
        # BUS=$(lspci | grep -E 'VGA|3D' | head -n1 | awk '{print $1}') && sudo lspci -vv -s "$BUS" | sed -n '/Resizable BAR/,+35p'
        "NVreg_EnableResizableBar=1"

        # disable screen dimming
        "NVreg_EnableBacklightHandler=0"
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
      "zswap.enabled=1" # enables zswap https://wiki.nixos.org/wiki/Swap

      # Enable reBar/SAM (shouldnt be necessary)
      # "pci=realloc"
      # "big_root_window"s

      # "drm.edid_firmware=DP-3:1024x768.bin"
      # "drm.edid_firmware=DP-3:edid/1024x768.bin"
      # "drm.edid_firmware=DP-3:edid/1920x1080.bin"
      # "drm.edid_firmware=DP-3:edid/msi-oled.bin"

      "clearcpuid=rdseed" # https://discussion.fedoraproject.org/t/rdseed32-is-broken-disabling-the-corresponding-cpuid-bit-rdseed-failure-on-amd-processors/173204/8
      "amdgpu.modeset=0" # disable amdgpu kernel driver to avoid conflicts with nvidia
    ];

    kernelModules = [
      "amdgpu"
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
      "i2c-nvidia-gpu" # for ddc/ci support, see ddcutil
      "i2c-dev" # for ddc/ci support, see ddcutil
      "ntsync"
    ];

    # Nvidia problems in 6.18.2 https://github.com/NixOS/nixpkgs/issues/473350
    blacklistedKernelModules = [
      # "nouveau"
      # "nova_core"
      # "amdgpu"
    ];

    kernel.sysctl = {
      "vm.dirty_bytes" = 67108864; # File transfer buffer -> Lower to imrpove write-to-usb feedback. 64 * 1024 * 1024 = 67108864
      "vm.swappiness" = 10; # default is 60, lower to reduce swap usage https://wiki.nixos.org/wiki/Swap#Adjusting_swap_usage_behaviour
      "kernel.numa_balancing" = 0; # Make sure NUMA auto balancing is off (good for games on single-socket)
    };
  };

  hardware.firmware = [
    pkgs.linux-firmware
    (pkgs.runCommand "edid-firmware" { } ''
      mkdir -p $out/lib/firmware/edid
      cp ${./msi-oled-edid.bin} $out/lib/firmware/edid/msi-oled.bin
    '')
  ];

  hardware.enableAllFirmware = true;

  # enable transparent hugepages
  systemd.tmpfiles.rules = [
    # Mode
    "w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise"
    # Defrag policy for THP page faults
    "w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    # khugepaged tunables (scanning background compaction)
    "w /sys/kernel/mm/transparent_hugepage/khugepaged/defrag - - - - 1"
    # Optional: control how aggressively khugepaged scans
    "w /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs - - - - 10000" # 10s
    "w /sys/kernel/mm/transparent_hugepage/khugepaged/alloc_sleep_millisecs - - - - 500" # 0.5s
  ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  virtualisation.docker.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # KDE stores overrides in ~/.config/plasma-localerc
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

  i18n.localeCharsets = {
    LANGUAGE = "de_DE.UTF-8";
    LC_ALL = "de_DE.UTF-8";
    LC_CTYPE = "de_DE.UTF-8";
    LC_COLLATE = "de_DE.UTF-8";
    LC_MESSAGES = "de_DE.UTF-8";
  };

  # i18n.supportedLocales = [ "all" ];
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
  ];
  # i18n.extraLocales = [ "all" ];

  # i18n.glibcLocales = pkgs.glibcLocales;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # services.xserver.enable = true;
  # services.displayManager.defaultSession = "plasmax11";
  programs.xwayland.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "stschiff";
  services.displayManager.sddm.enable = true; # maybe not needed due to autologin -> definitely needed
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
  # services.printing.drivers = [ pkgs.brlaser ];

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
    extraGroups = [
      "i2c"
      "networkmanager"
      "wheel"
      "libvirtd"
      "docker"
      "gamemode"
    ];
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
      c = "clear";
      cls = "clear";
      top = "htop";
      ls = "eza --oneline --all --icons --group-directories-first --color=always --total-size --no-permissions --no-user --long";
      l = "ls";
      ll = "ls";
      nrt = "sudo nixos-rebuild test";
      nrs = "() { git add . && git commit -m \"Prepare: $1\" || true && up && nh os switch /etc/nixos --diff never -- --impure && cur && gcp \"$1\" && gc && onedrivefix }";
      nrb = "() { git add . && git commit -m \"Prepare: $1\" || true && up && nh os boot /etc/nixos --diff never -- --impure && cur && gcp \"$1\" && gc }";
      nrsu = "sudo nix-channel --update && nrs \"System Update\"";
      nrsb = "nrs \"$1\" && gut";
      nrsrepair = "sudo nixos-rebuild switch --repair";
      gut = "qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot";
      gcp = "() {cd /etc/nixos && git add . && git commit -m \"Generation $(cur): $1\" && git push}";
      gcp_prepare = "() {cd /etc/nixos && git add . && git commit -m \"Prepare $1\"}";
      cur = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | cut -d \" \" -f 2";
      up = "cd /etc/nixos && nfl && nh os build /etc/nixos -- --impure && nvd diff /run/current-system ./result | tee /etc/nixos/nixdiff.txt && cat /etc/nixos/nixdiff.txt";
      gc = "nh clean all --keep 5 --keep-since 7d --quiet && fixicons";
      # https://github.com/NixOS/nixpkgs/issues/308252#issuecomment-2543048917
      fixicons = "sed -i 's/file:\\/\\/\\/nix\\/store\\/[^\\/]*\\/share\\/applications\\//applications:/gi' ~/.config/plasma-org.kde.plasma.desktop-appletsrc && systemctl restart --user plasma-plasmashell && echo 'Iconfix!\n\n'";
      nt = "nix-tree /nix/var/nix/profiles/system";
      onedrivefix = "systemctl --user enable onedrive.service && systemctl --user start onedrive.service && echo 'Onedrivefix!\n\n'";
      df = "dysk"; # better df

      # Update flake.lock for nixpkgs (pins nixpkgs input to latest flake)
      nfl = "cd /etc/nixos && nix flake update";
    };

    histSize = 50000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
      "INC_APPEND_HISTORY"
      "HIST_REDUCE_BLANKS"
    ];
  };
  # virtualisation.waydroid.enable = true;

  nix = {
    extraOptions = ''
      trusted-users = root stschiff
    '';
    settings = {
      system-features = [
        "gccarch-znver4"
        "gccarch-znver5"
        "nixos-test"
        "benchmark"
        "big-parallel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      cores = 24; # threads per build job https://search.nixos.org/options?channel=unstable&show=nix.settings.cores&query=nix.settings
      max-jobs = 4; # parallel build jobs https://search.nixos.org/options?channel=unstable&show=nix.settings.max-jobs&query=nix.settings
      extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
    };
    # nixPath = [
    # "nixpkgs=/home/stschiff/projects/nixpkgs"
    # "nixpkgs=https://nixos.org/channels/nixos-unstable"
    # "nixos-config=/etc/nixos/configuration.nix"
    # ];
  };

  programs.ccache.enable = true;
  # Note: ccache for kernel and nvidia is handled via overlays using ccacheStdenv
  programs.ccache.packageNames = [
    "ollama"
    "ollama-cuda"
    # "coreutils"
  ];

  programs.partition-manager.enable = true;

  fonts.enableDefaultPackages = true; # https://wiki.nixos.org/wiki/Fonts#Default_fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    google-fonts
    freetype
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

  # https://wiki.nixos.org/wiki/GameMode
  programs.gamemode = {
    enable = true;
    enableRenice = true;

    settings = {
      general = {
        renice = 10;
      };
    };
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vdpauinfo # sudo vainfo
      libva-utils # sudo vainfo
      nvidia-vaapi-driver # nvidia-smi dmon
      libva-vdpau-driver
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
    MANGOHUD_CONFIG = "fps_limit=100,no_display";
    MANGOHUD = "1";
    KWIN_DRM_USE_EGL_STREAMS = "1"; # Wayland GPU accel

    WEBKIT_DISABLE_DMABUF_RENDERER = "1"; # try to fix orca
    CUDA_TOOLKIT_ROOT_DIR = "${pkgs.cudaPackages.cudatoolkit}";

    LANGUAGE = "en_US.UTF-8";
    NIXOS_OZONE_WL = "1";

    PROTON_ENABLE_HDR = "1";
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_NO_WM_DECORATION = "1";
    DXVK_HDR = "1";
    ENABLE_HDR_WSI = "1";
    # DISPLAY = "";

    # KWIN_DRM_NO_AMS = "1"; # possible fix for display delay on startup
    # KWIN_DRM_FORCE_FORMATS = "0x1"; # possible fix for display delay on startup

    __GL_SHADER_DISK_CACHE = "1"; # enable shader cache
    __GL_SHADER_DISK_CACHE_SIZE = "53687091200"; # 50 GB
  };

  # https://wiki.nixos.org/wiki/NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = lib.mkDefault true;
    powerManagement.enable = false; # try false due to blackscreen on boot
    # powerManagement.finegrained = true; # requires offload to be enabled

    open = true; # Set to false for proprietary drivers -> https://download.nvidia.com/XFree86/Linux-x86_64/565.77/README/kernel_open.html
  };

  hardware.bluetooth = {
    enable = true;
    # settings.General.Experimental = true;
  };

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
      vscodeExtensions =
        with vscode-extensions;
        [
          arrterian.nix-env-selector
          bbenoist.nix
          charliermarsh.ruff # python linter
          github.codespaces
          github.copilot
          github.copilot-chat
          jnoortheen.nix-ide
          kamadorueda.alejandra
          mechatroner.rainbow-csv
          mkhl.direnv
          ms-azuretools.vscode-docker
          ms-python.debugpy
          ms-python.python
          ms-python.vscode-pylance
          # ms-python.vscode-python-envs
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode.cpptools
          redhat.vscode-xml
          rust-lang.rust-analyzer
          sumneko.lua
          tamasfe.even-better-toml
          tauri-apps.tauri-vscode
          thenuprojectcontributors.vscode-nushell-lang
          usernamehw.errorlens
          geequlim.godot-tools
          stephanzlatarev.vscode-starcraft
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "qml";
            publisher = "bbenoist";
            version = "1.0.0";
            sha256 = "sha256-tphnVlD5LA6Au+WDrLZkAxnMJeTCd3UTyTN1Jelditk=";
          }
        ];
    })

    # brave
    # mullvad-browser
    # ungoogled-chromium
    (chromium.override {
      enableWideVine = true;
      commandLineArgs = [
        "--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled"
        "--disable-new-avatar-menu"
      ];
    })
    widevine-cdm # streaming codec for chromium
    # vivaldi # crashes after a while https://github.com/NixOS/nixpkgs/issues/307424

    kdePackages.kate # editor with sudo
    thunderbird
    # my-vscode
    # bitwarden

    vesktop # change autostart Exec to: Exec=sleep 5  && vesktop
    # teamspeak3
    teamspeak6-client
    alsa-utils # amixer
    # pamixer

    dolphin-emu
    # lutris # gaming launcher -> added as system package
    # heroic # gaming launcher (epic)
    # libstrangle # frame limiter: steam command: strangle 140 %command%
    # gamescope # https://www.reddit.com/r/HuntShowdown/comments/1hdyetz/comment/m22pkci
    # gamescope -H 1440 -f -b --force-grab-cursor -- %command%
    mangohud
    goverlay # mangohud manager

    (lib.hiPrio uutils-coreutils-noprefix) # https://wiki.nixos.org/wiki/Uutils
    # alacritty # https://alacritty.org/config-alacritty.html
    # kitty
    wezterm # link .wezterm.lua to ~/.wezterm.lua
    starship
    # nushell
    zsh # link .zshrc to ~/.zshrc
    carapace
    tealdeer # tldr
    fastfetch
    stow
    devenv # meh
    direnv
    nix-direnv # https://github.com/nix-community/nix-direnv?tab=readme-ov-file#usage-example
    nvd
    stress
    pciutils
    btop
    bottom
    htop
    # warp-terminal
    # zellij # ctrl p n for new pane
    eza # ls replacement
    dysk # df replacement

    nh # nix os helper
    nix-tree
    nix-output-monitor

    p7zip # 7zip
    unrar
    k4dirstat # windirstat clone

    nil # nix lsp
    alejandra # nix formatter
    nixfmt
    ruff

    obsidian
    libreoffice
    pinta # graphic

    # for rustdev: use devenv
    # devenv init
    # -> copy file from ststat
    # devenv shell
    rustup

    vlc
    streamlink-twitch-gui-bin
    ffmpeg-full

    # kdePackages.kalk # wrong calculator!
    gnome-calculator
    transmission_4-qt
    krusader # file manager (like total commander) and ftp
    kde-rounded-corners

    # waydroid # also enable virtualisation.waydroid.enable

    git
    ntfs3g # allow read write ntfs mounts
    docker-compose

    # Wrapper that prioritizes Steam via systemd cgroup CPU weight
    (writeShellScriptBin "steam" ''
      #!/bin/sh
      # Change to home directory to avoid sandbox issues with /etc/nixos
      cd ~ || cd /tmp
      # Use systemd-run to apply CPU and IO scheduling priority (works unprivileged)
      exec ${pkgs.systemd}/bin/systemd-run --user --scope -p CPUWeight=2000 -p IOWeight=2000 ${pkgs.steam}/bin/steam "$@"
    '')
    protontricks
    protonplus
    steamtinkerlaunch # This is the important one! add as `steamtinkertlaunch %command%` in steam launch options
    (lutris.override {
      extraPkgs = pkgs: [
        umu-launcher
      ];
    })
    wineWowPackages.stable
    winetricks
    prismlauncher # minecraft https://wiki.nixos.org/wiki/Prism_Launcher
    protonup-rs
    r2modman # valheim mods
    rusty-path-of-building
    freetype

    # brlaser # printer

    # Orca segfaults if not run with mesa: https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
    # __GLX_VENDOR_LIBRARY_NAME=mesa __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json orca-slicer
    orca-slicer # broken cuda

    # bambu-studio # broken cuda
    # prusa-slicer # expensive to build o.o
    # unstable.cura # currently broken due to python
    # appimage-run # for cura
    # unstable.cura-appimage

    smartgit
    github-desktop

    webkitgtk_6_0

    # swtpm # tpm emulator for qemu

    # kdePackages.konqueror # for orcaslicer

    # onedrivegui # ist unnötig, siehe onedrive-wiki

    sqlitestudio

    gnome-software # for flatpaks

    lm_sensors
    linuxKernel.packages.linux_xanmod_latest.turbostat
    sysstat

    geekbench

    variety # wallpaper changer

    firefox

    adwaita-icon-theme
    gtk3

    # minion

    # cudaPackages.cudatoolkit

    rclone
    restic
    # restic-browser # depends on webkit, takes forever to build
    backrest

    libnotify # enables notify-send

    # (python3.withPackages (ps: [ps.websockets]))
    # cava # audio visualizer
    # qt6.qtwebsockets
    (callPackage /etc/nixos/derivations/exiled-exchange-2.nix { })
    (callPackage /etc/nixos/derivations/kurve.nix { })
    (callPackage /home/stschiff/projects/krosshair/derivation.nix { })
    # plasmusic-toolbar
    # kurve

    yt-dlp
    mp3gain
    scdl # soundcloud-dl

    # attempt gpu fix for orca-slicer
    mesa
    libglvnd

    heynote

    flameshot # screenshot tool

    libGL
    wayland
    wayland-protocols

    masterpdfeditor4

    # Temporarily remove protonvpn-gui to avoid a failing build in proton-core tests.
    # Reintroduce after upstream fixes or a proper patch is applied.
    # protonvpn-gui

    kdePackages.kde-cli-tools

    teams-for-linux
  ];

  # Enable GNOME settings manager
  programs.dconf.enable = true;
  programs.steam = {
    enable = true;
    # package = unstable.steam;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true;
    protontricks.enable = true;
  };

  programs.firefox = {
    enable = true;
    # package = pkgs.firefox;
    # https://github.com/TLATER/dotfiles/blob/master/nixos-modules/nvidia/default.nix
    preferences = {
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
  };

  programs.chromium = {
    extraOpts = {
      "ExtensionManifestV2Availability" = 2;
    };
  };

  # https://wiki.nixos.org/wiki/Appimage
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.nh = {
    enable = true;
  };

  # programs.tuxclocker.enable = true;
  # programs.tuxclocker.enabledNVIDIADevices = [
  #   "0" # nvidia gpu
  # ];

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

  # https://wiki.nixos.org/wiki/Sunshine
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  services.udev.packages = with pkgs; [
    # pkgs.platformio-core # embedded dev
    openocd # embedded debugger
    dolphin-emu
    ddcutil
  ];

  systemd.services.make_cpu_energy_readable = {
    description = "Make energy_uj readable for all users to allow displaying cpu power usage in ststat";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "make_cpu_energy_readable" "chmod a+r /sys/class/powercap/intel-rapl:0/energy_uj"}";
      # It’s often a good idea to mark the service active after the command finishes.
      RemainAfterExit = true;
    };
  };

  systemd.services.limit_gpu_power = {
    description = "Limit GPU power limit";
    wantedBy = [ "graphical.target" ];
    path = [
      config.boot.kernelPackages.nvidiaPackages.beta
    ];
    serviceConfig = {
      Type = "oneshot";
      user = "root";
      ExecStart = "${pkgs.writeShellScript "set_gpu_powerlimit" "nvidia-smi -pl 250"}";
      # It’s often a good idea to mark the service active after the command finishes.
      RemainAfterExit = true;
    };
  };

  systemd.services.gpu_overclock = {
    # See https://github.com/chrisheib/py_nvid_oc
    # Compile and put py_nvid_oc in /etc/nixos
    description = "GPU overclock";
    wantedBy = [ "graphical.target" ];
    path = [
      config.boot.kernelPackages.nvidiaPackages.beta
    ];
    serviceConfig = {
      Type = "oneshot";
      user = "root";
      Environment = "LD_LIBRARY_PATH=${config.boot.kernelPackages.nvidiaPackages.beta}/lib";
      ExecStart = "${pkgs.writeShellScript "set_gpu_overclock" "/etc/nixos/py_nvid_oc 125 800"}";
      # It’s often a good idea to mark the service active after the command finishes.
      RemainAfterExit = true;
    };
  };

  # defaults to port 9898
  systemd.services.backrest = {
    description = "Launch backrest to take care of backups";
    wantedBy = [ "graphical.target" ];
    requires = [ "network-online.target" ];
    script = "backrest";
    path = [
      pkgs.backrest
      pkgs.rclone
    ];
    environment = {
      BACKREST_PORT = "0.0.0.0:9898";
    };
    serviceConfig = {
      Type = "simple";
      User = "stschiff";
      AmbientCapabilities = "CAP_DAC_READ_SEARCH";
      CapabilityBoundingSet = "CAP_DAC_READ_SEARCH";
      # ExecStart = "backrest";
      # It’s often a good idea to mark the service active after the command finishes.
      # RemainAfterExit = true;
    };
  };

  # services.ollama = {
  #   enable = true;
  #   # acceleration = "cuda";
  #   package = pkgs.ollama-cuda;
  #   loadModels = [ "qwen3-embedding:0.6b" ];
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  programs.kdeconnect.enable = true;

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
