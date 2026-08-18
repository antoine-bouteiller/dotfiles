{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchurl,
}: let
  sourcesData = lib.importJSON ./sources.json;
  inherit (sourcesData) version;
  sources = sourcesData.platforms;

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "pi";
    inherit version;

    src = fetchurl {
      inherit (source) url hash;
    };

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      autoPatchelfHook
    ];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      stdenv.cc.cc.lib
    ];

    # The Bun-compiled binary resolves its support files (themes,
    # export-html, node_modules) relative to itself, so ship the whole
    # release tree and symlink the entry point.
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/pi $out/bin
      cp -r . $out/lib/pi
      chmod +x $out/lib/pi/pi
      ln -s $out/lib/pi/pi $out/bin/pi

      runHook postInstall
    '';

    dontStrip = true;

    passthru.updateScript = ./update.nu;

    meta = with lib; {
      inherit version;
      description = "pi coding agent";
      homepage = "https://github.com/earendil-works/pi";
      license = licenses.mit;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "pi";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      maintainers = [];
    };
  }
