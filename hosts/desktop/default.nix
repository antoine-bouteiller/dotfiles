{
  config,
  globals,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (globals) user;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports =
    [
      ../base-nixos.nix
      ./disko.nix
    ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  assertions = [
    {
      assertion = builtins.pathExists ./hardware-configuration.nix;
      message = "desktop: generate and git add hosts/desktop/hardware-configuration.nix before installing; see README.md.";
    }
  ];

  flakePath = "${config.users.users.${user}.home}/dotfiles";

  local.nixos.desktop.enable = true;
  local.nixos.gaming.enable = true;
  secureBoot.enable = true;

  # DHCP DNS is used per-network (required for captive portals); these are fallbacks.
  # The noctalia dns-switcher plugin flips the active profile's ipv4.dns to a public
  # resolver when the ISP one filters a domain.
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = ["1.1.1.1" "9.9.9.9"];
  };

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

  environment.systemPackages = with pkgs; [
    # Node.js development tools
    nodejs_24
    bun
    # customPkgs.vite-plus

    customPkgs.nearby-file-share
    customPkgs.helium

    xwayland-satellite

    # Plex's only DisplayManager backend is X11DisplayManager, which XOpenDisplay()s
    # $DISPLAY regardless of the Qt platform plugin; with no Xwayland it fails and
    # playback segfaults. xwayland-satellite plus DISPLAY :12 from the niri config is
    # enough, so no wrapper. Only the rename is left: the desktop entry basename must
    # equal the app_id (tv.plex.Plex) or the shell can't pair the window with an icon.
    (symlinkJoin {
      name = "plex-desktop-app-id";
      paths = [plex-desktop];
      postBuild = ''
        mv $out/share/applications/plex-desktop.desktop \
          $out/share/applications/tv.plex.Plex.desktop
      '';
    })
    telegram-desktop
    bitwarden-desktop
  ];

  # Keep the OS picker visible for Windows dual boot.
  boot.loader.timeout = 5;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs globals;
      hostUser = user;
    };
    users.${user} = import ./home.nix;
  };

  users.defaultUserShell = pkgs.zsh;
  users.users.${user} = {
    isNormalUser = true;
    description = globals.name;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  system.stateVersion = "25.11";
}
