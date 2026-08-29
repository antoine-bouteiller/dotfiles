# Catppuccin Mocha, spelled out for the apps with no Catppuccin port of their own
# and so have to be handed raw hex. Currently delta.
{lib}: let
  inherit
    (lib)
    concatStrings
    fromTOML
    removePrefix
    stringLength
    substring
    toHexString
    toLower
    zipListsWith
    ;

  hexToRgb = hex: let
    h = removePrefix "#" (toLower hex);
    # fromTOML is the only hex-literal parser nix has.
    parse = s: (fromTOML "v = 0x${s}").v;
  in
    map parse [(substring 0 2 h) (substring 2 2 h) (substring 4 2 h)];

  rgbToHex = channels:
    "#"
    + concatStrings (map (
        v: let
          s = toLower (toHexString v);
        in
          if stringLength s == 1
          then "0${s}"
          else s
      )
      channels);

  round = x: let
    below = builtins.floor x;
  in
    if x - below < 0.5
    then below
    else below + 1;
in {
  colors = {
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    blue = "#89b4fa";
    lavender = "#b4befe";
    text = "#cdd6f4";
    subtext1 = "#bac2de";
    subtext0 = "#a6adc8";
    overlay2 = "#9399b2";
    overlay1 = "#7f849c";
    overlay0 = "#6c7086";
    surface2 = "#585b70";
    surface1 = "#45475a";
    surface0 = "#313244";
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
  };

  # `ratio` is the weight of `a`: `mix base red 0.8` is base with a red cast.
  mix = a: b: ratio:
    rgbToHex (zipListsWith (x: y: round ((x * ratio) + (y * (1.0 - ratio)))) (hexToRgb a) (hexToRgb b));
}
