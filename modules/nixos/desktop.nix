{
  mkModule,
  pkgs,
  lib,
  inputs,
  host,
  ...
} @ args:
mkModule args "local.nixos.desktop" {
  description = "Niri Desktop";
  imports = [inputs.noctalia-greeter.nixosModules.default];

  config = _: let
    inherit (import ../../lib/palette.nix {inherit lib;}) colors;
    plymouthTheme = (pkgs.catppuccin-plymouth.override {variant = "mocha";}).overrideAttrs (old: {
      nativeBuildInputs = [pkgs.catppuccin-whiskers pkgs.imagemagick];
      buildPhase = let
        overrides = builtins.toJSON {
          mocha = lib.mapAttrs (_: lib.removePrefix "#") {
            inherit (colors) text red green yellow blue pink teal;
            base = colors.background;
            surface0 = colors.surfaceRaised;
          };
        };
      in ''
        runHook preBuild
        # Render upstream templates so icons and animation frames share the palette too.
        whiskers -f mocha --color-overrides '${overrides}' ${old.src}/plymouth.tera > catppuccin-mocha.plymouth
        for icon in bullet capslock entry keyboard lock; do
          whiskers -f mocha --color-overrides '${overrides}' ${old.src}/$icon.tera \
            | magick -background none svg:- "$icon.png"
        done
        for frame in {0..5}; do
          whiskers -f mocha --color-overrides '${overrides}' --overrides "{\"active\":$frame}" ${old.src}/throbber.tera \
            | magick -background none svg:- "throbber-$frame.png"
        done
        # Keep the two-tone snowflake, without a baked-in wallpaper background.
        sed -e 's/#699ad7\|#7eb1dd\|#7ebae4/${colors.cyan}/g' \
            -e 's/#415e9a\|#4a6baf\|#5277c3/${colors.blue}/g' \
          ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg > logo.svg
        magick -background none logo.svg -trim +repage -resize 295x256 logo.png
        rm logo.svg
        runHook postBuild
      '';
    });
  in {
    programs.niri.enable = true;
    programs.localsend.enable = true;

    networking.networkmanager.dns = "systemd-resolved";
    services.resolved = {
      enable = true;
      settings.Resolve.FallbackDNS = ["1.1.1.1" "9.9.9.9"];
    };

    local.nixos.tailscale.enable = true;
    services.tailscale.extraSetFlags = ["--operator=${host.user}"];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # A splash instead of the boot log. The kernel and udev have to be quietened
    # separately, or their messages tear through the splash; the LUKS passphrase
    # prompt is drawn by plymouth itself under the systemd initrd.
    boot = {
      plymouth = {
        enable = true;
        theme = "catppuccin-mocha";
        themePackages = [plymouthTheme];
        logo = "${plymouthTheme}/share/plymouth/themes/catppuccin-mocha/logo.png";
      };
      kernelParams = ["quiet" "splash" "udev.log_level=3"];
      consoleLogLevel = 0;
      initrd.verbose = false;
    };

    # The greeter enables greetd and points it at its own wlroots compositor; the
    # session list comes from the wayland-sessions entry niri ships.
    programs.noctalia-greeter = {
      enable = true;
      passwordless-sync-users = [host.user];
      settings = {
        # Noctalia auto-syncs its appearance to sync.toml through the constrained helper.
        appearance = {
          scheme = "Synced";
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

    # The key left of the spacebar -- Alt on a PC keyboard, Cmd on a Mac -- becomes a layer
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

    environment.systemPackages = [pkgs.xwayland-satellite];

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
