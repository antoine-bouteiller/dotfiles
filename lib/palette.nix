# Graphite-inspired neutrals with complementary accents for delta, Pi, and the console.
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
    blush = "#ead5cf";
    salmon = "#e6bfba";
    pink = "#e4b4ce";
    magenta = "#d2b4f8";
    red = "#f3a5a5";
    rose = "#d99ca7";
    orange = "#e8bc98";
    yellow = "#f1d79b";
    green = "#b5d99c";
    teal = "#a4d3c1";
    cyan = "#9edcde";
    steelBlue = "#92c3d9";
    blue = "#9acbff";
    periwinkle = "#bdc3ed";
    white = "#ffffff";
    black = "#000000";
    text = "#ffffff";
    textSecondary = "#e0e0e4";
    textMuted = "#d0d0d6";
    textSubtle = "#c0c0ca";
    textDim = "#aeaeb6";
    textFaint = "#9a9aa6";
    surfaceHover = "#505057";
    surfaceRaised = "#414146";
    surface = "#343438";
    background = "#303034";
    backgroundDim = "#2b2b2f";
    backgroundDark = "#26262a";
  };

  # `ratio` is the weight of `a`: `mix background red 0.8` gives a red-tinted background.
  mix = a: b: ratio:
    rgbToHex (zipListsWith (x: y: round ((x * ratio) + (y * (1.0 - ratio)))) (hexToRgb a) (hexToRgb b));
}
