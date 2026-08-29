# Every hyprland keybind. The half that pelico's aerospace config renders too comes
# from ../keymap.nix; the rest is hyprland/noctalia-only and stays here.
{lib}: let
  apps = {
    terminal = "foot";
    browser = "helium";
    explorer = "thunar";
  };
  mod = "SUPER";

  # Renders to hl.bind(keys, <dispatcher>, { flags }); dispatchers are raw lua.
  mkBind = flags: keys: dispatcher: {
    _args =
      [keys (lib.generators.mkLuaInline dispatcher)]
      ++ lib.optional (flags != {}) flags;
  };
  bind = mkBind {};
  bindLocked = mkBind {locked = true;};
  bindRepeat = mkBind {repeating = true;};
  bindRepeatLocked = mkBind {
    repeating = true;
    locked = true;
  };
  bindMouse = mkBind {mouse = true;};

  # The shared keys are physical positions, hence keycodes rather than symbols:
  # under fr/azerty code:52 is the key labelled W.
  keymap = import ../keymap.nix;
  key = name: "code:${toString keymap.keycodes.${name}}";
  chord = mods: k: lib.concatStringsSep " + " ([mod] ++ mods ++ [k]);
  dispatchers = {
    close = "hl.dsp.window.close()";
    float = "hl.dsp.window.float()";
    terminal = ''hl.dsp.exec_cmd("${apps.terminal}")'';
    browser = ''hl.dsp.exec_cmd("${apps.browser}")'';
    growWidth = "hl.dsp.window.resize({ x = 100, y = 0, relative = true })";
    shrinkWidth = "hl.dsp.window.resize({ x = -100, y = 0, relative = true })";
    growHeight = "hl.dsp.window.resize({ x = 0, y = 100, relative = true })";
    shrinkHeight = "hl.dsp.window.resize({ x = 0, y = -100, relative = true })";
  };
  sharedBinds =
    map (
      b:
        mkBind (lib.optionalAttrs (b.repeat or false) {repeating = true;})
        (chord (b.mods or []) (key b.key))
        dispatchers.${b.action}
    )
    keymap.binds
    ++ lib.concatMap (dir: [
      (bind (chord [] dir) ''hl.dsp.focus({ direction = "${lib.substring 0 1 dir}" })'')
      (bind (chord ["SHIFT"] dir) ''hl.dsp.window.move({ direction = "${lib.substring 0 1 dir}" })'')
    ])
    keymap.directions
    ++ lib.concatLists (lib.imap1 (index: k: [
        (bind (chord [] (key k)) ''hl.dsp.focus({ workspace = "${toString index}" })'')
        (bind (chord ["SHIFT"] (key k)) ''hl.dsp.window.move({ workspace = "${toString index}" })'')
      ])
      keymap.workspaceKeys);
in
  [
    (bind "${mod} + F" ''hl.dsp.exec_cmd("${apps.explorer}")'')
    (bind "${mod} + N" ''hl.dsp.exec_cmd("${apps.terminal} -e nvim")'')
    (bind "${mod} + T" ''hl.dsp.exec_cmd("${apps.terminal} -e btop")'')
    (bind "${mod} + Space" ''hl.dsp.exec_cmd("noctalia msg panel-toggle launcher")'')
    (bind "${mod} + S" ''hl.dsp.exec_cmd("noctalia msg panel-toggle control-center")'')
    (bind "${mod} + Escape" ''hl.dsp.exec_cmd("noctalia msg panel-toggle session")'')
    (bind "${mod} + I" ''hl.dsp.exec_cmd("noctalia msg settings-open")'')
    (bind "CTRL + ${mod} + L" ''hl.dsp.exec_cmd("noctalia msg session lock")'')
    (bind "${mod} + V" ''hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard")'')
    # The launcher's emoji provider is triggered by typing its prefix.
    (bind "CTRL + ${mod} + E" ''hl.dsp.exec_cmd("noctalia msg panel-open launcher '/emo '")'')
    (bind "SHIFT + F11" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')
    (bind "ALT + F11" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
    (bind "${mod} + SHIFT + S" ''hl.dsp.exec_cmd("noctalia msg screenshot-region")'')
    (bind "${mod} + Print" ''hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a")'')
    (bind "${mod} + mouse_down" ''hl.dsp.focus({ workspace = "+1" })'')
    (bind "${mod} + mouse_up" ''hl.dsp.focus({ workspace = "-1" })'')

    (bindRepeat "ALT + Tab" "hl.dsp.window.cycle_next()")
    (bindRepeat "SHIFT + ALT + Tab" "hl.dsp.window.cycle_next({ next = false })")
    (bindRepeat "${mod} + Tab" ''hl.dsp.focus({ workspace = "+1" })'')
    (bindRepeat "${mod} + SHIFT + Tab" ''hl.dsp.focus({ workspace = "-1" })'')

    (bindMouse "${mod} + mouse:272" "hl.dsp.window.drag()")
    (bindMouse "${mod} + mouse:273" "hl.dsp.window.resize()")

    (bindLocked "Print" ''hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen")'')
    (bindLocked "${mod} + comma" ''hl.dsp.exec_cmd("noctalia msg notification-clear-active")'')
    (bindLocked "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("noctalia msg brightness-up")'')
    (bindLocked "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("noctalia msg brightness-down")'')
    (bindLocked "XF86AudioPlay" ''hl.dsp.exec_cmd("noctalia msg media toggle")'')
    (bindLocked "XF86AudioPause" ''hl.dsp.exec_cmd("noctalia msg media toggle")'')
    (bindLocked "XF86AudioNext" ''hl.dsp.exec_cmd("noctalia msg media next")'')
    (bindLocked "XF86AudioPrev" ''hl.dsp.exec_cmd("noctalia msg media previous")'')
    (bindLocked "XF86AudioMute" ''hl.dsp.exec_cmd("noctalia msg volume-mute")'')
    (bindLocked "XF86AudioMicMute" ''hl.dsp.exec_cmd("noctalia msg mic-mute")'')

    (bindRepeatLocked "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("noctalia msg volume-up")'')
    (bindRepeatLocked "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("noctalia msg volume-down")'')
  ]
  ++ sharedBinds
