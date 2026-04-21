{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  sassc,
  gtk-engine-murrine,
}:
stdenvNoCC.mkDerivation {
  pname = "we10x-gtk-theme";
  version = "0-unstable-2025-05-12";

  src = fetchFromGitHub {
    owner = "yeyushengfan258";
    repo = "We10X-gtk-theme";
    rev = "ee2475ecbd35bb5b9f28407a21ce1c005b4db663";
    hash = "sha256-4fn+v7rdxoDqtHracPBTxcJ+7vxli6vnUKLyWSk9Jrw=";
  };

  nativeBuildInputs = [sassc];
  propagatedUserEnvPkgs = [gtk-engine-murrine];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    patchShebangs install.sh
    mkdir -p $out/share/themes
    HOME=$TMPDIR ./install.sh --dest $out/share/themes --color dark
    runHook postInstall
  '';

  meta = with lib; {
    description = "We10X Windows 10X-like GTK theme";
    homepage = "https://github.com/yeyushengfan258/We10X-gtk-theme";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
