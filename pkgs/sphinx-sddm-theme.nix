{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "sphinx-sddm-theme";
  version = "0-unstable-2026-04-03";

  src = fetchFromGitHub {
    owner = "TheCollectiveDevelopers";
    repo = "sphinx";
    rev = "7df2e30dca21d0801f30cafd3964ada774e35214";
    hash = "sha256-DuDuYAO7aYKc4KCjnzsAdTZaaEtPqyjP7eiV6JaesfA=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sddm/themes
    cp -r sphinx-greeter $out/share/sddm/themes/sphinx
    runHook postInstall
  '';

  meta = with lib; {
    description = "SphinxOS SDDM greeter theme (Theme-API 2.0, Qt 6)";
    homepage = "https://github.com/TheCollectiveDevelopers/sphinx";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
