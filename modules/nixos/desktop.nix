{
  mkModule,
  pkgs,
  lib,
  inputs,
  ...
} @ args:
mkModule args "local.nixos.desktop" {
  description = "Niri Desktop";
  imports = [inputs.noctalia-greeter.nixosModules.default];

  config = _: {
    programs.niri.enable = true;

    # The greeter enables greetd and points it at its own wlroots compositor; the
    # session list comes from the wayland-sessions entry niri ships.
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        # "Synced" takes its palette from noctalia's Sync, which writes sync.toml
        # next to this file from the running shell -- the greeter then matches the desktop.
        appearance = {
          scheme = "Synced";
          theme_mode = "dark";
          hide_logo = true;
        };
        keyboard = {
          layout = "fr";
          variant = "azerty";
        };
        # The greeter runs as the greetd user, so the theme has to be pointed at.
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
          path = "${pkgs.bibata-cursors}/share/icons";
        };
      };
    };

    # greetd's pam stack is `include login`, so dropping fprintd here forces a typed password
    # at the greeter -- the only thing that reaches pam_gnome_keyring and unlocks the keyring.
    # swaylock, sudo and polkit-1 keep fingerprint; tty login loses it, being this stack.
    security.pam.services.login.fprintAuth = false;

    # The key left of the spacebar -- Alt here, Cmd on the MacBook -- becomes a layer
    # carrying Ctrl, so the same physical key copies and closes tabs on both machines.
    # keyd remaps below the compositor, so this covers every app.
    #
    # Each key maps onto Ctrl + itself rather than onto a named letter: the fr layout
    # is applied after keyd, so the key labelled W arrives as Ctrl+w unaided.
    #
    # The layer inherits Alt (`cmd:A`), leaving Alt+Tab and Alt+F11 alone. Terminals
    # are the casualty: Cmd+C reaches foot as SIGINT, so copy there stays Ctrl+Shift+C.
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = ["*"];
        settings = {
          main.leftalt = "layer(cmd)";
          "cmd:A" =
            lib.genAttrs
            (lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz0123456789" ++ ["minus" "equal"])
            (key: "C-${key}");
        };
      };
    };

    environment.sessionVariables.NIXOS_OZONE_WL = 1;

    # noctalia's gtk template applies itself through gsettings.
    programs.dconf.enable = true;

    # Secret Service provider (org.freedesktop.secrets): without it chromium falls back to
    # its plaintext store and NetworkManager keeps wifi PSKs system-wide. The module wires
    # pam_gnome_keyring into `login` itself, so the greeter password unlocks it unaided.
    services.gnome.gnome-keyring.enable = true;

    # noctalia's battery and power-profile widgets talk to these daemons over D-Bus.
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    # No system76-scheduler here: its cfs-profiles write sysctls that EEVDF removed in
    # 6.6, and its foreground boost needs a GNOME/COSMIC client to report the focused
    # window, so under niri only the de-boost half lands -- launcher-started apps
    # match its system-services profile (nice 12, idle IO) and get starved.

    # The niri module already pulls in the gnome portal; GTK is what its own portal
    # config lists as the fallback for Access and Notification.
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
}
