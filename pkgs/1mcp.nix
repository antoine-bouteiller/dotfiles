{
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm,
  pnpmConfigHook,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "1mcp";
  version = "0.30.3";

  src = fetchFromGitHub {
    owner = "1mcp-app";
    repo = "agent";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ndRHBsKs5HcbybpWwO7BoZAChtm2D9X3uTwxP6dr5OM=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-JNiLhojoJdpT5b3L0zj1hZLd1o/PjaeETuHnIaZmtH0=";
    fetcherVersion = 3;
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/1mcp $out/bin
    cp -r build node_modules package.json $out/lib/1mcp/
    makeWrapper ${nodejs}/bin/node $out/bin/1mcp \
      --add-flags "$out/lib/1mcp/build/index.js"

    runHook postInstall
  '';

  meta = {
    description = "One MCP server to aggregate them all";
    homepage = "https://github.com/1mcp-app/agent";
    mainProgram = "1mcp";
  };
})
