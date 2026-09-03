{
  mkModule,
  lib,
  ...
} @ args: let
  inherit (lib) mkDefault;
in
  mkModule args "local.home-manager.workstation" {
    description = "A machine used for development, as opposed to a server";
    # mkDefault throughout: a host can switch one item off without leaving the profile.
    config = _: {
      local.home-manager = {
        herdr.enable = mkDefault true;
        hunk.enable = mkDefault true;
        shell-tools.enable = mkDefault true;
        zed.enable = mkDefault true;
        terminal.enable = mkDefault true;
        agents = {
          enable = mkDefault true;
          claude-code.enable = mkDefault true;
          pi.enable = mkDefault true;
        };
      };
    };
  }
