{
  lib,
  fetchurl,
  appimageTools,
  nix-update,
  writeShellScript,
}: let
  pname = "helium";
  version = "0.15.3.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-ZCCm/prkgYgbDHW6OBPWvoIE77g7IYQpYdqc/PnIrSU=";
  };

  contents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm644 ${contents}/helium.desktop $out/share/applications/helium.desktop
      substituteInPlace $out/share/applications/helium.desktop \
        --replace-fail 'Exec=helium' "Exec=$out/bin/helium"
      cp -r ${contents}/usr/share/icons $out/share/icons
    '';

    passthru.updateScript = writeShellScript "${pname}-update" ''
      exec ${nix-update}/bin/nix-update --flake ${pname}
    '';

    meta = {
      description = "Private, fast, and honest web browser based on Chromium";
      homepage = "https://helium.computer";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = "helium";
    };
  }
