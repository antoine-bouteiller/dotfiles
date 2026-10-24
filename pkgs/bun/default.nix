{
  lib,
  stdenv,
  bun,
  fetchurl,
}: let
  sourcesData = lib.importJSON ./sources.json;
in
  # `bun build --compile` copies its own executable, so the binary must stay
  # unpatched or compiled outputs depend on /nix/store. NixOS runs it via nix-ld.
  bun.overrideAttrs (old: {
    inherit (sourcesData) version;
    __intentionallyOverridingVersion = true;
    dontAutoPatchelf = true;
    postPatchelf = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      bun=$out/bin/bun
      ${lib.optionalString stdenv.hostPlatform.isLinux ''
        bun="${stdenv.cc.bintools.dynamicLinker} $bun"
      ''}
      installShellCompletion --cmd bun \
        --bash <(SHELL="bash" $bun completions) \
        --zsh <(SHELL="zsh" $bun completions) \
        --fish <(SHELL="fish" $bun completions)
    '';
    passthru =
      old.passthru
      // {
        sources = builtins.mapAttrs (_: fetchurl) sourcesData.platforms;
        updateScript = ./update.nu;
      };
  })
