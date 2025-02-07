# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}: let
  system = builtins.currentSystem;
  extensions =
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/nix-vscode-extensions";
      ref = "refs/heads/master";
      rev = "cb0aee6840fb29b70439880656ca6a313a6af101";
    }))
    .extensions
    .${system};
  extensionsList = with extensions.vscode-marketplace; [
    filiptibell.tooling-language-server
    # rust-lang.rust-analyzer
  ];

  # Wrap vscode with --no-sandbox args, so it can run sudo from within the terminal.
  my-vscode-no-sandbox = pkgs.vscode-with-extensions.overrideAttrs (oldAttrs: rec {
    postFixup = ''
      ${oldAttrs.postFixup or ""}
        wrapProgram $out/bin/executable-name \
          --run "code --no-sandbox"
    '';
  });

  unstable = import <nixos-unstable> {config = {allowUnfree = true;};};
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # To switch to unstable nixpgks:
  # sudo nix-channel --list
  # sudo nix-channel --remove nixos
  # sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
  # Or as overlay: https://www.reddit.com/r/NixOS/comments/17v4o9i/comment/k9akqcv

  boot = {
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
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
      # theme = "rings";
      # themePackages = with pkgs; [
      #   # By default we would install all themes
      #   (adi1090x-plymouth-themes.override {
      #     selected_themes = ["rings"];
      #   })
      # ];
    };

    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 1;

    # Enable "Silent Boot"
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  virtualisation.docker.enable = true;

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
  services.xserver.enable = true;
  services.displayManager.defaultSession = "plasmax11";
  # programs.xwayland.enable = true;

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
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.stschiff = {
    isNormalUser = true;
    description = "stschiff";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      kdePackages.kate # editor with sudo
      thunderbird
      (my-vscode-no-sandbox.override {
        # vscode = vscodium;
        # extraArguments = "--no-sandbox";
        vscodeExtensions = with vscode-extensions;
          [
            tauri-apps.tauri-vscode
            bbenoist.nix
            ms-python.python
            ms-azuretools.vscode-docker
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            jnoortheen.nix-ide
            kamadorueda.alejandra
            rust-lang.rust-analyzer
            usernamehw.errorlens
            tamasfe.even-better-toml
            mkhl.direnv
            thenuprojectcontributors.vscode-nushell-lang
          ]
          ++ extensionsList;
      })
      unstable.bitwarden

      unstable.vesktop
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

      bottom
      nushell
      carapace
      tealdeer #tldr
      neofetch
      stow
      devenv
      direnv
      nvd
      stress
      pciutils

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

      vlc
      streamlink-twitch-gui-bin

      transmission_4-qt

      prismlauncher # minecraft https://wiki.nixos.org/wiki/Prism_Launcher

      kdePackages.kalk # calculator
    ];
  };

  # LD_LIBRARY_PATH = with pkgs;
  #   lib.makeLibraryPath [
  #     libGL
  #     libxkbcommon
  #     wayland
  #     xorg.libX11
  #     xorg.libXcursor
  #     xorg.libXi
  #     xorg.libXrandr
  #   ];
  # ...
  # LD_LIBRARY_PATH = libPath;

  nix.extraOptions = ''
    trusted-users = root stschiff
  '';

  # Also change config.nu! (in nushell: config nu)
  programs.bash.shellAliases = {
    l = "ls -alh";
    ll = "ls -l";
    ls = "ls --color=tty";
    nrt = "sudo nixos-rebuild test";
    nrs = "sudo nixos-rebuild switch && cur && gcp";
    nrsrepair = "sudo nixos-rebuild switch --repair";
    nrsu = "sudo nix-channel --update && nrs";
    nrsb = "nrs && gut";
    cur = "sudo echo -n 'Current Generation: ' && sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'";
    gut = "qdbus org.kde.Shutdown /Shutdown  org.kde.Shutdown.logoutAndReboot";
    gcp = "(cd ~/.nixos && git add . && git commit -m \"Generation $(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')\" && git push)";
  };

  programs.partition-manager.enable = true;

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  services.udev.packages = [pkgs.dolphin-emu];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true;
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
      "steam-original"
      "steam-run"
    ];

  programs.gamemode.enable = true; # https://wiki.nixos.org/wiki/GameMode

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vdpauinfo # sudo vainfo
      libva-utils # sudo vainfo
      nvidia-vaapi-driver # nvidia-smi dmon
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
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    NVD_BACKEND = "direct";
    # EGL_PLATFORM = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1";
    MANGOHUD_CONFIG = "fps_limit=140,no_display";
    MANGOHUD = "1";
    KWIN_DRM_USE_EGL_STREAMS = "1"; # Wayland GPU accel
  };

  # https://wiki.nixos.org/wiki/NVIDIA
  services.xserver.videoDrivers = ["nvidia"];
  # services.xserver.videoDrivers = ["nvidia" "intel"];
  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    # Power management is nearly always required to get nvidia GPUs to
    # behave on suspend, due to firmware bugs.
    powerManagement.enable = true;
    open = true; # Set to false for proprietary drivers -> https://download.nvidia.com/XFree86/Linux-x86_64/565.77/README/kernel_open.html
    # prime = {
    # offload.enable = true;
    # offload.enableOffloadCmd = true;

    # intelBusId = "PCI:0:2:0";
    # nvidiaBusId = "PCI:1:0:0";
    # };
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "stschiff";

  # Install firefox.
  programs.firefox.enable = true;

  # https://github.com/TLATER/dotfiles/blob/master/nixos-modules/nvidia/default.nix
  programs.firefox.preferences = {
    "media.ffmpeg.vaapi.enabled" = true;
    "media.rdd-ffmpeg.enabled" = true;
    "media.av1.enabled" = true;
    "gfx.x11-egl.force-enabled" = true;
    "widget.dmabuf.force-enabled" = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vdpauinfo # sudo vainfo
    libva-utils # sudo vainfo
    # nvidia-vaapi-driver
    git
    ntfs3g # allow read write ntfs mounts
    docker-compose
    (lutris.override {
      extraPkgs = pkgs: [
        unstable.umu-launcher
      ];
    })
    wineWowPackages.stable
    winetricks

    brlaser # printer

    unstable.orca-slicer

    # kdePackages.konqueror # for orcaslicer
  ];

  # Resolve local hostnames via ip4: https://discourse.nixos.org/t/help-with-local-dns-resolution/20305/5
  system.nssModules = pkgs.lib.optional true pkgs.nssmdns;
  system.nssDatabases.hosts = pkgs.lib.optionals true (pkgs.lib.mkMerge [
    (pkgs.lib.mkBefore ["mdns4_minimal [NOTFOUND=return]"]) # before resolve
    (pkgs.lib.mkAfter ["mdns4"]) # after dns
  ]);

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
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
