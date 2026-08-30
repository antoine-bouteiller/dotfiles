# Bindings shared between niri on dell and paneru on pelico; the action set is the
# intersection of the two, anything one-sided stays in its own renderer. Both are
# scrollable-tiling, so the vocabulary is columns and rows rather than a tree.
#
# Keys are named by physical position using US layout names, which is how paneru
# labels macOS virtual keycodes and what the niri renderer turns into fr keysyms.
# Both being positional is what makes one entry hit the same key under azerty.
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
  };

  # Rendered bare to focus and with SHIFT to move the focused window.
  directions = ["left" "right" "up" "down"];

  # Top-row digits, 0 being the tenth workspace.
  workspaceKeys = ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"];

  binds = [
    {
      action = "float";
      key = "v";
      mods = ["Shift"];
    }
    {
      action = "growWidth";
      key = "equal";
    }
    {
      action = "shrinkWidth";
      key = "minus";
    }
  ];
}
