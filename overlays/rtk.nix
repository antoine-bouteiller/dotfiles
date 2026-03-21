{rtk-src}: final: prev: {
  rtk = prev.rustPlatform.buildRustPackage {
    pname = "rtk";
    version = rtk-src.shortRev or rtk-src.rev or "unstable";

    src = rtk-src;
    cargoLock.lockFile = "${rtk-src}/Cargo.lock";

    doCheck = false;

    meta = {
      description = "High-performance CLI proxy to reduce LLM token consumption";
      homepage = "https://github.com/rtk-ai/rtk";
      mainProgram = "rtk";
    };
  };
}
