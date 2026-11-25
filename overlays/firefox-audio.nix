final: prev:
let
  firefoxAudioUnwrapped = prev.firefox-unwrapped.overrideAttrs (old: {
    version = "161.0-audio";
    src = final.fetchFromGitHub {
      owner = "chrisheib";
      repo = "firefox";
      rev = "9b2555d4f4a602337e455bff3cbe4d785095f0a5";
      hash = "sha256-BkxwDX/VOjluBhQOdbW8sXH0Wfcx/1EeTpOcbWeJpJ0=";
    };

    patches = [ ];
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace toolkit/xre/nsXREDirProvider.cpp \
          --replace-fail \
          'rv = NS_NewNativeLocalFile(dirname, getter_AddRefs(localDir));' \
          'const char* pathVar = PR_GetEnv("MOZ_SYSTEM_DIR");
          rv = NS_NewNativeLocalFile(
              (pathVar && *pathVar) ? nsDependentCString(pathVar)
                                    : reinterpret_cast<const nsCString&>(dirname),
              getter_AddRefs(localDir));'

        substituteInPlace docshell/base/nsAboutRedirector.cpp \
          --replace-fail \
          '    {"buildconfig", "chrome://global/content/buildconfig.html",
             nsIAboutModule::URI_SAFE_FOR_UNTRUSTED_CONTENT |
                 nsIAboutModule::IS_SECURE_CHROME_UI},' \
          ""

        substituteInPlace toolkit/content/jar.mn \
          --replace-fail \
          "*   content/global/buildconfig.html" \
          ""

        cat > sourcestamp.txt <<'EOF'
        20261120000000
        https://github.com/chrisheib/firefox/commit/9b2555d4f4a602337e455bff3cbe4d785095f0a5
        EOF
      '';

    meta = old.meta // {
      description = "Firefox with selectable time-stretching audio engines";
      homepage = "https://github.com/chrisheib/firefox";
    };
    passthru = (old.passthru or { }) // {
      version = "161.0-audio";
    };
  });
in
{
  firefox-unwrapped = firefoxAudioUnwrapped;
  firefox = prev.wrapFirefox firefoxAudioUnwrapped {
    version = "161.0-audio";
  };
}
