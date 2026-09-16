{
  lib,
  stdenv,
  fetchurl,
  fetchzip,
  makeWrapper,
}: let
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;

  source =
    sources.platforms.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "engram";
    inherit version;

    src = fetchurl {
      inherit (source) url hash;
    };

    # The release tarball contains the binary at its root.
    sourceRoot = ".";

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      install -Dm755 engram $out/bin/engram
      wrapProgram $out/bin/engram --set ENGRAM_NO_UPDATE_CHECK 1

      runHook postInstall
    '';

    passthru = {
      updateScript = ./update.nu;
      piExtension = "${fetchzip {
        url = "https://github.com/Gentleman-Programming/engram/archive/refs/tags/v${version}.tar.gz";
        hash = sources.sourceHash;
      }}/plugin/pi";
    };

    meta = with lib; {
      description = "Persistent memory system for AI coding agents";
      homepage = "https://engram.gentlemanprogramming.com/";
      license = licenses.mit;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "engram";
      platforms = ["x86_64-linux" "aarch64-darwin"];
      maintainers = [];
    };
  }
