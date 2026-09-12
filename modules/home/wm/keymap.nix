# Niri tiling bindings use US physical positions, mapped to fr/azerty keysyms.
{
  # niri resolves binds through the active xkb layout, so every US position is
  # spelled as the keysym that position emits under fr/azerty.
  azerty = {
    "1" = "ampersand";
    "2" = "eacute";
    "3" = "quotedbl";
    "4" = "apostrophe";
    "5" = "parenleft";
    "6" = "minus";
    "7" = "egrave";
    "8" = "underscore";
    "9" = "ccedilla";
    "0" = "agrave";
    minus = "parenright";
    equal = "equal";
    return = "Return";
    z = "W";
    v = "V";
    b = "B";
    j = "J";
    k = "K";
    l = "L";
    semicolon = "M";
    r = "R";
  };

  # Rendered bare to focus and with SHIFT to move the focused window.
  directions = ["left" "right" "up" "down"];

  # Vim's HJKL slid one key right, so the home row reads J K L M under azerty.
  # Bound alongside the arrows, not instead of them.
  directionLetters = {
    left = "j";
    down = "k";
    up = "l";
    right = "semicolon";
  };

  # Column widths to cycle through, as fractions of the screen.
  presetWidths = [0.33333 0.5 0.66667 1.0];

  # Top-row digits, 0 being the tenth workspace.
  workspaceKeys = ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"];

  binds = [
    {
      action = "float";
      key = "v";
      mods = ["Shift"];
    }
    # `once` because holding the key would run through the whole preset list.
    {
      action = "cycleWidth";
      key = "r";
      once = true;
    }
    {
      action = "cycleWidthBack";
      key = "r";
      mods = ["Shift"];
      once = true;
    }
  ];
}
