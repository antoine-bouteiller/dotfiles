{
  mkModule,
  lib,
  ...
} @ args:
mkModule args "local.home-manager.gaming" {
  description = "Steam desktop-entry fixups for gaming hosts";
  config = _: {
    # SMAPI prefers Steam's xterm; Xlib reads this without an xrdb session service.
    programs.noctalia.settings.theme.templates.user.xterm = {
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/xterm.Xresources";
      output_path = "~/.Xdefaults";
    };
    xdg.configFile."noctalia/templates/xterm.Xresources".text = ''
      XTerm*background: {{ colors.terminal_background.default.hex }}
      XTerm*foreground: {{ colors.terminal_foreground.default.hex }}
      XTerm*cursorColor: {{ colors.terminal_cursor.default.hex }}
    '';

    home.activation.fixSteamIcons = lib.hm.dag.entryAfter ["writeBoundary"] ''
      for f in ~/.local/share/applications/*.desktop; do
        id=$(grep -Eo 'steam://rungameid/[0-9]+' "$f" | sed 's#.*/##') || true
        [ -n "$id" ] || continue
        last=$(tail -n1 "$f" || true)
        want="StartupWMClass=steam_app_$id"
        [ "$last" = "$want" ] || echo "$want" >> "$f"
      done
    '';
  };
}
