{
  lib,
  fetchurl,
  appimageTools,
  runCommand,
  nix-update,
  writeShellScript,
}: let
  pname = "amethyst-mod-manager";
  version = "2.5.0";

  src = fetchurl {
    url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v${version}/AmethystModManager-${version}-x86_64.AppImage";
    hash = "sha256-f8ugHVQnuq0D9o2sox9gjvr0HDqOfr0jQCCowxrk2J8=";
  };

  # Upstream uses DwarFS, which appimageTools.extract does not support.
  contents = runCommand "${pname}-${version}-extracted" {} ''
    cp ${src} appimage
    chmod +x appimage
    ./appimage --appimage-extract
    cp -a squashfs-root/. $out
  '';
in
  appimageTools.wrapAppImage {
    inherit pname version;
    src = contents;

    # The bundled Python's sqlite3 module needs a library absent from the AppImage.
    extraPkgs = pkgs: [pkgs.sqlite];

    extraInstallCommands = ''
      install -Dm644 ${contents}/mod-manager.desktop $out/share/applications/amethyst-mod-manager.desktop
      substituteInPlace $out/share/applications/amethyst-mod-manager.desktop \
        --replace-fail 'Exec=mod-manager' "Exec=$out/bin/${pname}"
      install -Dm644 ${contents}/mod-manager.png $out/share/icons/hicolor/256x256/apps/mod-manager.png
    '';

    passthru = {
      inherit src;
      updateScript = writeShellScript "${pname}-update" ''
        exec ${nix-update}/bin/nix-update --flake ${pname}
      '';
    };

    meta = {
      description = "Linux-native mod manager for a variety of games";
      homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
    };
  }
