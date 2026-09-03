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
    pname = "ai-usagebar";
    inherit version;

    src = fetchurl {inherit (source) url hash;};

    # The tarball's members sit at its root, so there is no directory to strip.
    sourceRoot = ".";

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [stdenv.cc.cc.lib];

    installPhase = ''
      runHook preInstall

      install -Dm755 ai-usagebar ai-usagebar-tui -t $out/bin

      runHook postInstall
    '';

    passthru.updateScript = ./update.nu;

    meta = with lib; {
      inherit version;
      description = "CLI reporting AI plan quota usage across providers";
      homepage = "https://github.com/akitaonrails/ai-usagebar";
      license = licenses.mit;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "ai-usagebar";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
