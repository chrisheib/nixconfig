# self: super:
# let
#   # Base functions
#   pyMods = super.development.python-modules;

#   # Wrap coverage: no-op test phase, forces new name
#   coverageWrapped =
#     args:
#     (pyMods.coverage args).overrideAttrs (_: {
#       doCheck = false;
#       checkPhase = "echo 'skip coverage tests'";
#       pythonRuntimeDepsCheck = false;
#       pythonImportsCheck = [ ];
#       name = "coverage-${(pyMods.coverage args).version}-nocheck";
#     });

#   # Wrap pytest-randomly: disable all checks and make runtime-deps check happy
#   pytestRandomlyWrapped =
#     args:
#     (pyMods.pytest-randomly args).overrideAttrs (old: {
#       doCheck = false;
#       checkPhase = "echo 'skip pytest-randomly checks'";
#       pythonRuntimeDepsCheck = false;
#       pythonImportsCheck = [ ];
#       # if some evaluation still runs pythonRuntimeDepsCheck, add pytest at runtime:
#       propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
#         (args.python or super.python3) # ensure python present in args
#         (args.pytest or super.python313Packages.pytest or super.python3Packages.pytest)
#       ];
#       name = "pytest-randomly-${(pyMods.pytest-randomly args).version}-nocheck";
#     });
# in
# {
#   # Make the patched functions the ones every python set calls
#   development = super.development // {
#     python-modules = super.development.python-modules // {
#       coverage = coverageWrapped;
#       pytest-randomly = pytestRandomlyWrapped;
#     };
#   };

#   # Assimp: keep tests off (works for you)
#   assimp = super.assimp.overrideAttrs (_: {
#     doCheck = false;
#   });

#   # Also re-export from common sets to eliminate ambiguity
#   python313Packages = super.python313Packages.override {
#     overrides = pySelf: pySuper: {
#       coverage = pySuper.coverage;
#       pytest-randomly = pySuper.pytest-randomly;
#     };
#   };
#   python3Packages = super.python3Packages.override {
#     overrides = pySelf: pySuper: {
#       coverage = pySuper.coverage;
#       pytest-randomly = pySuper.pytest-randomly;
#     };
#   };
# }

# self: super:
# let
#   # Original function for the raw module
#   coverageRaw = super.development.python-modules.coverage;

#   # Wrapper: disables tests unconditionally and forces a new name
#   coverageWrapped =
#     args:
#     (coverageRaw args).overrideAttrs (_old: {
#       # even if hooks set doCheck=true, we no-op the phase
#       doCheck = false;
#       checkPhase = "echo 'Skipping coverage tests via overlay'";
#       pytestFlagsArray = [ ];
#       disabledTests = [ ];
#       name = "coverage-${(coverageRaw args).version}-nocheck";
#     });
# in
# {
#   # 0) Make the wrapped coverage visible at the raw location so ANY python set gets it
#   development = super.development // {
#     python-modules = super.development.python-modules // {
#       coverage = coverageWrapped;
#     };
#   };

#   # 1) Also ensure common sets re-export the same coverage (belt & suspenders)
#   python313Packages = super.python313Packages.override {
#     overrides = pySelf: pySuper: { coverage = pySuper.coverage; };
#   };
#   python3Packages = super.python3Packages.override {
#     overrides = pySelf: pySuper: { coverage = pySuper.coverage; };
#   };

#   # 2) Your assimp fix (works for you)
#   assimp = super.assimp.overrideAttrs (_: {
#     doCheck = false;
#   });
# }

# self: super:
# let
#   # Keep a handle to the original function
#   coverageRaw = super.development.python-modules.coverage;

#   # Wrap it so all callers receive doCheck = false and a tweaked name
#   coverageWrapped =
#     args:
#     (coverageRaw args).overrideAttrs (_: {
#       doCheck = false;
#       name = "coverage-${(coverageRaw args).version}-nocheck";
#     });
# in
# {
#   # assimp: disable tests (works for you already)
#   assimp = super.assimp.overrideAttrs (_: {
#     doCheck = false;
#   });

#   # Replace the base coverage function used by all Python sets
#   development = super.development // {
#     python-modules = super.development.python-modules // {
#       coverage = coverageWrapped;
#     };
#   };

#   # Optional: keep these so set-level coverage resolves to the wrapped one
#   python313Packages = super.python313Packages.override {
#     overrides = pySelf: pySuper: { coverage = pySuper.coverage; };
#   };
#   python3Packages = super.python3Packages.override {
#     overrides = pySelf: pySuper: { coverage = pySuper.coverage; };
#   };
# }

# self: super: {
#   assimp = super.assimp.overrideAttrs (old: {
#     doCheck = false; # ctest won’t run
#   });
#   python313Packages = super.python313Packages.override {
#     overrides = pySelf: pySuper: {
#       coverage = pySuper.coverage.overridePythonAttrs (_: {
#         doCheck = false;
#         # force a new drv to ensure the change is used
#         name = "coverage-${pySuper.coverage.version}-nocheck";
#       });
#     };
#   };
# }
#   # If you still want the znver5 flag injection globally, keep your mkDerivation
#   # override here. Otherwise, drop it.

# self: super:
# let
#   # Wrap the raw coverage function so all Python sets see doCheck=false.
#   coverageWrapped =
#     args:
#     (super.development.python-modules.coverage args).overrideAttrs (_: {
#       doCheck = false;
#       name = "coverage-${(super.development.python-modules.coverage args).version}-nocheck";
#     });
# in
# {
#   # Keep assimp with default stdenv
#   assimp = super.assimp.override { stdenv = super.stdenv; };

#   # 1) Override the raw function used by all Python package sets
#   development = super.development // {
#     python-modules = super.development.python-modules // {
#       coverage = coverageWrapped;
#     };
#   };

#   # Optional: also wire common sets to ensure consistency (harmless if redundant)
#   python3Packages = super.python3Packages.override {
#     overrides = pySelf: pySuper: { coverage = pySuper.coverage; };
#   };
#   python313Packages = super.python313Packages.override {
#     overrides = pySelf: pySuper: { coverage = pySuper.coverage; };
#   };
# }

# self: super:
# let
#   disableCoverage =
#     pySelf: pySuper:
#     pySuper.coverage.overridePythonAttrs (_: {
#       doCheck = false;
#       name = "coverage-${pySuper.coverage.version}-nocheck";
#     });
# in
# {
#   # keep assimp on plain stdenv
#   assimp = super.assimp.override { stdenv = super.stdenv; };

#   # Apply to Python 3.13 and common aliases
#   python313Packages = super.python313Packages.override {
#     overrides = pySelf: pySuper: { coverage = disableCoverage pySelf pySuper; };
#   };

#   # Some nixpkgs also expose `python3Packages` → wire it too, but reuse the same instance
#   python3Packages = self.python313Packages;

#   # If python 3.12 is present, also override it (harmless if unused)
#   python312Packages =
#     if super ? python312Packages then
#       super.python312Packages.override {
#         overrides = pySelf: pySuper: { coverage = disableCoverage pySelf pySuper; };
#       }
#     else
#       super.python312Packages or null;
# }

# self: super: {
#   # 1. assimp keeps the original stdenv (no znver5 flags)
#   assimp = super.assimp.override { stdenv = super.stdenv; };

#   # 2. turn off *all* tests for coverage
#   python313Packages = super.python313Packages.override {
#     overrides = pySelf: pySuper: {
#       coverage = pySuper.coverage.overridePythonAttrs (_: {
#         doCheck = false;
#         # force a new drv to ensure the change is used
#         name = "coverage-${pySuper.coverage.version}-nocheck";
#       });
#     };
#   };
# }

# self: super: {
#   # 1. assimp keeps the original stdenv (no znver5 flags)
#   assimp = super.assimp.override { stdenv = super.stdenv; };

#   # 2. disable the exact XML tests that choke on store paths
#   python3Packages = super.python3Packages.override {
#     overrides = self: super: {
#       coverage = super.coverage.overridePythonAttrs (old: {
#         disabledTests = (old.disabledTests or [ ]) ++ [
#           "XmlIncludeOmitTest::test_omit_2" # exact pytest node-id
#           "XmlIncludeOmitTest" # whole class – optional
#           "ReportIncludeOmitTest::test_omit"
#           "ReportIncludeOmitTest::test_omit_2"
#           "ReportIncludeOmitTest::test_omit_as_string"
#           "test_nothing_specified"
#           "test_omit"
#           "test_omit_2"
#           "test_omit_as_string"
#         ];
#       });
#     };
#   };

#   # 3. global znver5 flags (assimp exempted above)
#   mkDerivation =
#     args:
#     super.mkDerivation (
#       args
#       // {
#         NIX_CFLAGS_COMPILE = (args.NIX_CFLAGS_COMPILE or "") + " -march=znver5 -mtune=znver5";
#       }
#     );
# }

# self: super: {
#   # 1. assimp keeps the original stdenv (no znver5 flags)
#   assimp = super.assimp.override { stdenv = super.stdenv; };

#   # 2. turn off *all* tests for coverage
#   python3Packages = super.python3Packages.override {
#     overrides = self: super: {
#       coverage = super.coverage.overridePythonAttrs (_: {
#         doCheck = false;
#       });
#     };
#   };

#   # 3. global znver5 flags (assimp exempted above)
#   mkDerivation =
#     args:
#     super.mkDerivation (
#       args
#       // {
#         NIX_CFLAGS_COMPILE = (args.NIX_CFLAGS_COMPILE or "") + " -march=znver5 -mtune=znver5";
#       }
#     );
# }

self: super: {
  # 1. assimp keeps the original stdenv (no znver5 flags)
  assimp = super.assimp.override { stdenv = super.stdenv; };
}
#   # 2. disable the exact XML tests that choke on store paths
#   python3Packages = super.python3Packages.override {
#     overrides = self: super: {
#       coverage = super.coverage.overridePythonAttrs (old: {
#         disabledTests = (old.disabledTests or [ ]) ++ [
#           "XmlIncludeOmitTest"
#           "XmlIncludeOmitTest::test_omit"
#           "XmlIncludeOmitTest::test_omit_2"
#           "XmlIncludeOmitTest::test_omit_as_string"
#           "ReportIncludeOmitTest"
#           "ReportIncludeOmitTest::test_omit"
#           "ReportIncludeOmitTest::test_omit_2"
#           "ReportIncludeOmitTest::test_omit_as_string"
#         ];
#       });
#     };
#   };

#   # 3. global znver5 flags (assimp exempted above)
#   mkDerivation =
#     args:
#     super.mkDerivation (
#       args
#       // {
#         NIX_CFLAGS_COMPILE = (args.NIX_CFLAGS_COMPILE or "") + " -march=znver5 -mtune=znver5";
#       }
#     );
# }

# self: super:
# let
#   # import the channel's nixpkgs as a separate instance without architecture-specific arguments
#   pkgsPlain = import <nixpkgs> { system = "x86_64-linux"; };
# in
# {
#   # assimp = pkgsPlain.assimp; # https://github.com/NixOS/nixpkgs/issues/440270
#   # 1. assimp with plain toolchain
#   assimp = super.assimp.overrideAttrs (old: {
#     stdenv = pkgsPlain.stdenv;
#     cc = pkgsPlain.stdenv.cc;
#   });

#   # 2. disable coverage tests
#   python3Packages = super.python3Packages.override {
#     overrides = self: super: {
#       coverage = super.coverage.overrideAttrs (_: {
#         doCheck = false;
#       });
#     };
#   };
# }

# override python3Packages to change only the 'coverage' package
# python3Packages = super.python3Packages.override {
#   overrides = self: super: {
#     coverage = super.coverage.overrideAttrs (old: {
#       doCheck = false;
#     });
#   };
# };

# gnutls = pkgsPlain.gnutls; # https://github.com/NixOS/nixpkgs/issues/440279
# swtpm = pkgsPlain.swtpm; # need to make an issue...
# cups = pkgsPlain.cups; # need to make an issue...
# gtk2 = pkgsPlain.gtk2; # need to make an issue...
# samba = pkgsPlain.samba; # need to make an issue...
# samba4Full = pkgsPlain.samba4Full; # need to make an issue...
# ghostscript = pkgsPlain.ghostscript; # need to make an issue...
# ghostscriptX = pkgsPlain.ghostscriptX; # need to make an issue...
# ibus = pkgsPlain.ibus; # need to make an issue...
# libopenmpt = pkgsPlain.libopenmpt; # need to make an issue...
# ffmpeg-headless = pkgsPlain.ffmpeg-headless; # need to make an issue...
# chromaprint = pkgsPlain.chromaprint; # need to make an issue...
# gst_all_1 = pkgsPlain.gst_all_1; # need to make an issue...
# libcanberra = pkgsPlain.libcanberra; # need to make an issue...
# libcamera = pkgsPlain.libcamera; # need to make an issue...

# # haskell.compiler.ghc967 = pkgsPlain.haskell.compiler.ghc965; # performance
# haskellpackages = pkgsPlain.haskellPackages; # performance
# ghc = pkgsPlain.ghc; # performance
# llvm = pkgsPlain.llvm; # performance
# llvm_20 = pkgsPlain.llvm_20; # performance
# llvm_18 = pkgsPlain.llvm_18; # performance
# ldc = pkgsPlain.ldc; # performance
# SPIRV-LLVM-Translator = pkgsPlain.SPIRV-LLVM-Translator; # performance
# mesa = pkgsPlain.mesa; # performance

# clang-wrapper = pkgsPlain.clang-wrapper; # performance
# clang = pkgsPlain.clang; # performance
# clang_15 = pkgsPlain.clang_15; # performance
# clang_16 = pkgsPlain.clang_16; # performance
# clang_17 = pkgsPlain.clang_17; # performance
# clang_18 = pkgsPlain.clang_18; # performance
# clang_19 = pkgsPlain.clang_19; # performance
# clang_20 = pkgsPlain.clang_20; # performance
# clang_multi = pkgsPlain.clang_multi; # performance
# libclang = pkgsPlain.libclang; # performance

# flac = pkgsPlain.flac; # performance
# gssdp = pkgsPlain.gssdp; # performance
# pandoc-cli = pkgsPlain.pandoc-cli; # performance
