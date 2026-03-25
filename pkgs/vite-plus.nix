{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}: let
  pname = "vite-plus";
  version = "0.1.14";

  # Map Nix systems to npm package suffixes
  systemMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64-gnu";
    "aarch64-linux" = "linux-arm64-gnu";
  };

  # Map Nix systems to hashes
  hashMap = {
    "aarch64-darwin" = "sha256-qBsGpfV4SUlWwa3DGU7OPswvL46bJB3uz9sbvl2ilG8=";
    "x86_64-darwin" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    "x86_64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Extract current system data, falling back to a clear error message
  system = stdenvNoCC.hostPlatform.system;
  platform = systemMap.${system} or (throw "Unsupported system: ${system}");
  hash = hashMap.${system} or (throw "Unsupported system: ${system}");
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-${platform}/-/vite-plus-cli-${platform}-${version}.tgz";
      inherit hash;
    };

    nativeBuildInputs = lib.optionals stdenvNoCC.isLinux [
      autoPatchelfHook
    ];

    sourceRoot = "package";

    installPhase = ''
      runHook preInstall

      install -Dm755 vp $out/bin/vp

      runHook postInstall
    '';

    meta = {
      description = "Vite+ unified web development toolchain CLI";
      homepage = "https://viteplus.dev";
      platforms = builtins.attrNames systemMap;
      mainProgram = "vp";
    };
  }
