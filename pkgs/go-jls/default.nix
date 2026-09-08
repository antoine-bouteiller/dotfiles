{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule {
  pname = "go-jls";
  # No tagged releases yet (only v0.0.0); track main.
  version = "0-unstable-2026-06-10";

  src = fetchFromGitHub {
    owner = "kamichidu";
    repo = "go-jls";
    rev = "349e0eb31d15de34aab9568655c27a22c9866195";
    hash = "sha256-ntgISDO6xJkmzXXpVmrjOEJGiJ1orRfqFv/EdqcjSGI=";
  };

  vendorHash = "sha256-DabjswCm3TKSHrT0MVkpTyliMZ8Czme3W0Ga7lL+Dqw=";

  subPackages = ["cmd/go-jls"];

  doCheck = false;

  passthru.updateScript = ./update.nu;

  meta = {
    description = "On-demand, low-latency Java Language Server written in Go";
    homepage = "https://github.com/kamichidu/go-jls";
    license = lib.licenses.mit;
    mainProgram = "go-jls";
  };
}
