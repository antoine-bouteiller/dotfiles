{
  config,
  inputs,
  lib,
  mkUserService,
  pkgs,
  ...
} @ args: let
  cfg = config.local.home-manager.agents;
  system = pkgs.stdenv.hostPlatform.system;
  package = inputs.meridian.packages.${system}.default.override {
    claude-code = inputs.self.packages.${system}.claude-code;
  };
in {
  config = lib.mkIf (cfg.enable && cfg.pi.enable && cfg.claude-code.enable) (lib.mkMerge [
    {
      home.packages = [package];

      xdg.configFile."meridian/sdk-features.json" = {
        force = true;
        text = builtins.toJSON {
          pi.codeSystemPrompt = false;
        };
      };
    }
    (mkUserService args "meridian" {
      description = "Meridian agent";
      command = lib.getExe package;
      environment = {
        MERIDIAN_MAX_CONCURRENT = "4";
        MERIDIAN_NO_FILE_CHANGES = "1";
        MERIDIAN_TELEMETRY_PERSIST = "1";
        MERIDIAN_TELEMETRY_RETENTION_DAYS = "2";
      };
    })
  ]);
}
