{
  lib,
  fetchurl,
  appimageTools,
  libva,
  makeWrapper,
  nix-update,
  writeShellScript,
}: let
  pname = "helium";
  version = "0.15.7.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-+zGEGfhIiZWE8mUYb3HrkoM7reFBMdfXlgw3KWT0T98=";
  };

  contents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    # Chromium dlopens libva.so.2 for hardware video decode; the AppImage bundles no copy
    # and appimageTools' FHS env has none, so VA-API is missing without this.
    extraPkgs = _: [libva];

    nativeBuildInputs = [makeWrapper];

    extraInstallCommands = ''
      install -Dm644 ${contents}/helium.desktop $out/share/applications/helium.desktop
      substituteInPlace $out/share/applications/helium.desktop \
        --replace-fail 'Exec=helium' "Exec=$out/bin/helium"
      cp -r ${contents}/usr/share/icons $out/share/icons

      # Chromium gates VA-API decode behind this feature when it renders through GL, and
      # the AppImage honours no flags file, so the flag has to live in the wrapper.
      wrapProgram $out/bin/helium \
        --add-flags --enable-features=AcceleratedVideoDecodeLinuxGL
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
