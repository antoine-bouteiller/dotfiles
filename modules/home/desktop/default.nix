{
  mkModule,
  inputs,
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
  config = _: {};
}
