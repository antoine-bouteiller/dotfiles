{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}: let
  sources = lib.importJSON ./sources.json;
in
  stdenvNoCC.mkDerivation {
    pname = "rex";
    inherit (sources) version;

    src = fetchurl {inherit (sources) url hash;};

    nativeBuildInputs = [undmg];
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications $out/bin
      cp -R "Rex Beta.app" $out/Applications/
      ln -s "$out/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex" $out/bin/rex

      runHook postInstall
    '';

    # Fixup would rewrite files under the upstream code signature, and its symlink check
    # rejects the dangling XPCServices link Sparkle ships.
    dontFixup = true;

    passthru.updateScript = ./update.nu;

    meta = {
      description = "Terminal multiplexer app with a scriptable local server";
      homepage = "https://www.superlogical.com/rex";
      license = lib.licenses.unfree;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = "rex";
      platforms = lib.platforms.darwin;
    };
  }
