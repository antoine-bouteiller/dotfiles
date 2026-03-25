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
  version = "0.30.2";

  src = fetchFromGitHub {
    owner = "1mcp-app";
    repo = "agent";
    rev = "v${finalAttrs.version}";
    hash = "sha256-BRwT+Z+IA5qMONTP4XH/0v7URPetkAvfGOUzhIf68qI=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-9c0Ogy8HcirXGiYBZQDCn6oZEhg1aPVLMhQi6ZvfauY=";
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
