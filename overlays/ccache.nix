# Ccache overlay for faster builds of kernel and nvidia drivers
# Pass `config` as argument to access ccache settings
config: self: super: {
  ccacheWrapper = super.ccacheWrapper.override {
    extraConfig = ''
      export CCACHE_COMPRESS=1
      export CCACHE_DIR="${config.programs.ccache.cacheDir}"
      export CCACHE_UMASK=007
      if [ ! -d "$CCACHE_DIR" ]; then
        echo "====="
        echo "Directory '$CCACHE_DIR' does not exist"
        echo "Please create it with:"
        echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
        echo "  sudo chown root:nixbld '$CCACHE_DIR'"
        echo "====="
        exit 1
      fi
      if [ ! -w "$CCACHE_DIR" ]; then
        echo "====="
        echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
        echo "Please verify its access permissions"
        echo "====="
        exit 1
      fi
    '';
  };
  # Create a ccache-enabled Clang stdenv for cachyos-lto kernel
  ccacheClangStdenv = super.ccacheStdenv.override {
    stdenv = super.clangStdenv;
  };
  # Enable ccache for the cachyos-lto kernel (needs clang)
  linuxPackages_cachyos-lto = super.linuxPackages_cachyos-lto.override {
    stdenv = self.ccacheClangStdenv;
  };
  # Enable ccache for nvidia driver
  nvidiaPackages = super.nvidiaPackages // {
    beta = (
      super.nvidiaPackages.beta.override {
        stdenv = super.ccacheStdenv;
      }
    );
    stable = (
      super.nvidiaPackages.stable.override {
        stdenv = super.ccacheStdenv;
      }
    );
    open = (
      super.nvidiaPackages.open.override {
        stdenv = super.ccacheStdenv;
      }
    );
  };
}
