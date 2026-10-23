{
  inputs,
  lib,
  mkModule,
  mkUserService,
  pkgs,
  ...
} @ args: let
  package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.ai-usagebar;
in
  mkModule args "local.home-manager.ai-usagebar" {
    description = "AI Usage menu bar app";
    config = _:
      lib.mkMerge [
        {
          assertions = [
            {
              assertion = pkgs.stdenv.hostPlatform.isDarwin;
              message = "local.home-manager.ai-usagebar ships the macOS menu bar app only.";
            }
          ];
          home.packages = [package];
          # Background throttling would make the popover sluggish.
          launchd.agents.ai-usagebar.config.ProcessType = lib.mkForce "Interactive";
        }
        # Replaces the tray's own "Start at Login", which would pin a store path that GC removes.
        (mkUserService args "ai-usagebar" {
          description = "AI Usage menu bar app";
          command = "${package}/Applications/AI Usage.app/Contents/MacOS/ai-usagebar-tray";
        })
      ];
  }
