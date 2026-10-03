{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchurl,
}: let
  sourcesData = lib.importJSON ./sources.json;
  inherit (sourcesData) version;

  source =
    sourcesData.platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "lightpanda";
    inherit version;

    src = fetchurl {inherit (source) url hash;};

    dontUnpack = true;

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook];

    installPhase = ''
      runHook preInstall

      install -Dm755 $src $out/bin/lightpanda

      runHook postInstall
    '';

    passthru.updateScript = ./update.nu;

    meta = with lib; {
      inherit version;
      description = "Headless browser designed for AI and automation";
      homepage = "https://lightpanda.io";
      license = licenses.agpl3Only;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "lightpanda";
      platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    };
  }
