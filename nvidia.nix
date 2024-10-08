# {
#   config,
#   inputs,
#   settings,
#   ...
# }:
# let
#   pkgs = import inputs.nixpkgs-unstable {
#     system = settings.system.platform;
#     config.allowUnfree = true;
#   };
# in
# {
#   environment.systemPackages = with pkgs; [ cudatoolkit ];
#
#   hardware.opengl.enable = true;
#   boot.kernelPackages = pkgs.linuxPackages_latest;
#   services.xserver.videoDrivers = [ "nvidia" ];
#
#   boot.kernelParams = [
#     "nvidia-drm.modeset=1"
#     "nvidia-drm.fbdev=1"
#   ];
#
#   nixpkgs.config.packageOverrides = pkgs: { inherit (pkgs) linuxPackages_latest nvidia_x11; };
#   hardware.nvidia = {
#     powerManagement = {
#       enable = true;
#       finegrained = false;
#     };
#     open = false;
#     nvidiaSettings = true;
#     package = config.boot.kernelPackages.nvidiaPackages.beta;
#   };
# }
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    setLdLibraryPath = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      vaapiVdpau
      # intel-media-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {LIBVA_DRIVER_NAME = "nvidia";};

  nixpkgs.config.packageOverrides = pkgs: {inherit (pkgs) linuxPackages_latest nvidia_x11;};

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;

    # package = config.boot.kernelPackages.nvidiaPackages.beta;

    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #   version = "560.35.03";
    #   sha256_64bit = "sha256-8pMskvrdQ8WyNBvkU/xPc/CtcYXCa7ekP73oGuKfH+M=";
    #   sha256_aarch64 = "sha256-s8ZAVKvRNXpjxRYqM3E5oss5FdqW+tv1qQC2pDjfG+s=";
    #   openSha256 = "sha256-/32Zf0dKrofTmPZ3Ratw4vDM7B+OgpC4p7s+RHUjCrg=";
    #   settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
    #   persistencedSha256 = "sha256-E2J2wYYyRu7Kc3MMZz/8ZIemcZg68rkzvqEwFAL3fFs=";
    # };
  };

  services.xserver.videoDrivers = ["nvidia"];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];
}
#  # Load nvidia driver for Xorg and Wayland
#  # breaks everything :(
#  services.xserver.videoDrivers = ["nvidia"];
#
#  # boot.kernelParams = ["nvidia.NVreg_PreserveVideoMemoryAllocations=0"];
#
#  hardware.nvidia = {
#    # package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
#
#    # Vulkan errors...
#    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
#    #   version = "560.35.03";
#    #   sha256_64bit = "sha256-8pMskvrdQ8WyNBvkU/xPc/CtcYXCa7ekP73oGuKfH+M=";
#    #   sha256_aarch64 = "sha256-s8ZAVKvRNXpjxRYqM3E5oss5FdqW+tv1qQC2pDjfG+s=";
#    #   openSha256 = "sha256-/32Zf0dKrofTmPZ3Ratw4vDM7B+OgpC4p7s+RHUjCrg=";
#    #   settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
#    #   persistencedSha256 = "sha256-E2J2wYYyRu7Kc3MMZz/8ZIemcZg68rkzvqEwFAL3fFs=";
#    # };
#
#    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
#      version = "555.58";
#      sha256_64bit = "sha256-bXvcXkg2kQZuCNKRZM5QoTaTjF4l2TtrsKUvyicj5ew=";
#      sha256_aarch64 = lib.fakeSha256;
#      openSha256 = lib.fakeSha256;
#      settingsSha256 = "sha256-vWnrXlBCb3K5uVkDFmJDVq51wrCoqgPF03lSjZOuU8M=";
#      persistencedSha256 = lib.fakeSha256;
#    };
#    modesetting.enable = true;
#    powerManagement.enable = true; # required for sleep on 555.58
#    powerManagement.finegrained = false;
#    nvidiaSettings = true;
#  };
#  nixpkgs.config.nvidia.acceptLicense = true;
#
#  # hardware.nvidia = {
#
#    # Modesetting is required.
#    # modesetting.enable = true;
#
#    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
#    # Enable this if you have graphical corruption issues or application crashes after waking
#    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
#    # of just the bare essentials.
#    # powerManagement.enable = false;
#
#    # Fine-grained power management. Turns off GPU when not in use.
#    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
#    # powerManagement.finegrained = false;
#
#    # Use the NVidia open source kernel module (not to be confused with the
#    # independent third-party "nouveau" open source driver).
#    # Support is limited to the Turing and later architectures. Full list of
#    # supported GPUs is at:
#    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
#    # Only available from driver 515.43.04+
#    # Currently alpha-quality/buggy, so false is currently the recommended setting.
#    # open = false;
#
#    # Enable the Nvidia settings menu,
#	  # accessible via `nvidia-settings`.
#    # nvidiaSettings = true;
#
#    # https://discourse.nixos.org/t/unable-to-build-nix-due-to-nvidia-drivers-due-or-kernel-6-10/49266/17
#    # https://www.gamingonlinux.com/articles/category/Nvidia/
#
#    # Optionally, you may need to select the appropriate driver version for your specific GPU.
#    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
#    #   version = "560.35.03";
#    #   sha256_64bit = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
#    # };
#    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
#    #   version = "555.58.02";
#    #   sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
#    #   sha256_aarch64 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
#    #   openSha256 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
#    #   settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
#    #   persistencedSha256 = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
#    # };
#  # };
#
#}

