# Bindings shared between hyprland on dell and aerospace on pelico; the action set
# is the intersection of the two, anything one-sided stays in its own renderer.
#
# Keys are named by physical position using US layout names, which is how aerospace
# identifies them and what the hyprland renderer turns into X11 keycodes. Both being
# positional is what makes one entry hit the same key under dell's fr/azerty.
{
  # X11 keycodes, i.e. evdev + 8.
  keycodes = {
    "1" = 10;
    "2" = 11;
    "3" = 12;
    "4" = 13;
    "5" = 14;
    "6" = 15;
    "7" = 16;
    "8" = 17;
    "9" = 18;
    "0" = 19;
    minus = 20;
    equal = 21;
    return = 36;
    z = 52;
    v = 55;
    b = 56;
  };

  # Rendered bare to focus and with SHIFT to move the focused window.
  directions = ["left" "right" "up" "down"];

  # Top-row digits, 0 being the tenth workspace.
  workspaceKeys = ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"];

  binds = [
    # The US-Z position is the key labelled W under azerty, which is the one dell
    # has always closed windows with.
    {
      action = "close";
      key = "z";
    }
    {
      action = "float";
      key = "v";
      mods = ["SHIFT"];
    }
    {
      action = "terminal";
      key = "return";
    }
    {
      action = "browser";
      key = "b";
    }
    {
      action = "growWidth";
      key = "equal";
      repeat = true;
    }
    {
      action = "shrinkWidth";
      key = "minus";
      repeat = true;
    }
    {
      action = "growHeight";
      key = "equal";
      mods = ["SHIFT"];
      repeat = true;
    }
    {
      action = "shrinkHeight";
      key = "minus";
      mods = ["SHIFT"];
      repeat = true;
    }
  ];
}
