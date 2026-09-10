{
  mkModule,
  config,
  inputs,
  lib,
  pkgs,
  ...
} @ args:
mkModule args "local.home-manager.desktop" {
  description = "Niri desktop session: gtk/qt theming and the noctalia shell";
  imports = [
    inputs.noctalia.homeModules.default
    ./gtk.nix
    ./qt.nix
    ./noctalia.nix
  ];
  options.extraNiriConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Host-specific KDL appended to niri's config, e.g. output blocks";
  };

  config = _: {
    local.home-manager.terminal.enable = lib.mkDefault true;

    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin || config.programs.foot.enable;
        message = "local.home-manager.desktop: the Niri session launches foot; enable local.home-manager.terminal or programs.foot.";
      }
    ];
  };
}
