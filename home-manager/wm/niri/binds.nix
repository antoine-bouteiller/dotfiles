# Every niri keybind, rendered as the lines of a `binds` node. The half that
# pelico's paneru config renders too comes from ../keymap.nix; the rest is
# niri/noctalia-only and stays here.
{lib}: let
  apps = {
    terminal = "foot";
    browser = "helium";
    explorer = "thunar";
    picker = "wl-color-picker";
  };
  mod = "Mod";

  # The shared keys are physical positions, hence the azerty keysym each one
  # emits: under fr the key labelled W sits where US has Z.
  keymap = import ../keymap.nix;
  key = name: keymap.azerty.${name};
  chord = mods: k: lib.concatStringsSep "+" ([mod] ++ mods ++ [k]);

  # niri binds repeat while held; only spawns and toggles opt out.
  mkBind = props: keys: action: let
    rendered = lib.concatMapStrings (p: " ${p}") props;
  in "${keys}${rendered} { ${action}; }";
  bind = mkBind [];
  once = mkBind ["repeat=false"];
  locked = mkBind ["repeat=false" "allow-when-locked=true"];
  lockedRepeat = mkBind ["allow-when-locked=true"];
  scroll = mkBind ["cooldown-ms=150"];

  spawn = args: "spawn ${lib.concatMapStringsSep " " (a: ''"${a}"'') args}";
  noctalia = args: spawn (["noctalia" "msg"] ++ args);

  dispatchers = {
    float = "toggle-window-floating";
    growWidth = ''set-window-width "+100"'';
    shrinkWidth = ''set-window-width "-100"'';
  };
  focusDirection = {
    left = "focus-column-left";
    right = "focus-column-right";
    up = "focus-window-up";
    down = "focus-window-down";
  };
  moveDirection = {
    left = "move-column-left";
    right = "move-column-right";
    up = "move-window-up";
    down = "move-window-down";
  };
  directionKeys = {
    left = "Left";
    right = "Right";
    up = "Up";
    down = "Down";
  };

  sharedBinds =
    map (
      b: bind (chord (b.mods or []) (key b.key)) dispatchers.${b.action}
    )
    keymap.binds
    ++ lib.concatMap (dir: [
      (bind (chord [] directionKeys.${dir}) focusDirection.${dir})
      (bind (chord ["Shift"] directionKeys.${dir}) moveDirection.${dir})
    ])
    keymap.directions
    ++ lib.concatLists (lib.imap1 (index: k: [
        (once (chord [] (key k)) "focus-workspace ${toString index}")
        (once (chord ["Shift"] (key k)) "move-window-to-workspace ${toString index}")
      ])
      keymap.workspaceKeys);
in
  [
    (once "${mod}+${key "z"}" "close-window")
    (once "${mod}+${key "return"}" (spawn [apps.terminal]))
    (once "${mod}+${key "b"}" (spawn [apps.browser]))
    (bind "${mod}+Shift+${key "equal"}" ''set-window-height "+100"'')
    (bind "${mod}+Shift+${key "minus"}" ''set-window-height "-100"'')
    (once "${mod}+R" "switch-preset-column-width")
    (once "${mod}+Shift+R" "switch-preset-column-width-back")

    (once "${mod}+F" (spawn [apps.explorer]))
    (once "${mod}+N" (spawn [apps.terminal "-e" "nvim"]))
    (once "${mod}+T" (spawn [apps.terminal "-e" "btop"]))
    (once "${mod}+Space" (noctalia ["panel-toggle" "launcher"]))
    (once "${mod}+S" (noctalia ["panel-toggle" "control-center"]))
    (once "${mod}+Escape" (noctalia ["panel-toggle" "session"]))
    (once "${mod}+I" (noctalia ["settings-open"]))
    (once "Ctrl+${mod}+L" (noctalia ["session" "lock"]))
    (once "${mod}+V" (noctalia ["panel-toggle" "clipboard"]))
    # The launcher's emoji provider is triggered by typing its prefix.
    (once "Ctrl+${mod}+E" (noctalia ["panel-open" "launcher" "/emo "]))
    (once "Shift+F11" "fullscreen-window")
    (once "Alt+F11" "maximize-column")
    (once "${mod}+Shift+S" (noctalia ["screenshot-region"]))
    (once "${mod}+Print" (spawn [apps.picker]))
    (once "Alt+Tab" "focus-window-previous")
    (once "${mod}+Tab" "focus-workspace-down")
    (once "${mod}+Shift+Tab" "focus-workspace-up")

    (scroll "${mod}+WheelScrollDown" "focus-workspace-down")
    (scroll "${mod}+WheelScrollUp" "focus-workspace-up")

    (locked "Print" (noctalia ["screenshot-fullscreen"]))
    (locked "${mod}+comma" (noctalia ["notification-clear-active"]))
    (locked "XF86MonBrightnessUp" (noctalia ["brightness-up"]))
    (locked "XF86MonBrightnessDown" (noctalia ["brightness-down"]))
    (locked "XF86AudioPlay" (noctalia ["media" "toggle"]))
    (locked "XF86AudioPause" (noctalia ["media" "toggle"]))
    (locked "XF86AudioNext" (noctalia ["media" "next"]))
    (locked "XF86AudioPrev" (noctalia ["media" "previous"]))
    (locked "XF86AudioMute" (noctalia ["volume-mute"]))
    (locked "XF86AudioMicMute" (noctalia ["mic-mute"]))

    (lockedRepeat "XF86AudioRaiseVolume" (noctalia ["volume-up"]))
    (lockedRepeat "XF86AudioLowerVolume" (noctalia ["volume-down"]))
  ]
  ++ sharedBinds
