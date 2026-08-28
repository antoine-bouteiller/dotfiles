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
  imports = [
    ../base-nixos.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];

  flakePath = "${config.users.users.${user}.home}/dotfiles";

  desktop.enable = true;
  gaming.enable = true;
  secureBoot.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # nixos-hardware turns on PRIME offload, but offload alone leaves the dGPU powered
  # (power/control=on, ~2W at idle). Finegrained adds the runtime-PM udev rules so the
  # card drops to D3cold when unused. powerManagement.enable preserves VRAM across the
  # suspend/hibernate the lid switch triggers.
  hardware.nvidia.powerManagement = {
    enable = true;
    finegrained = true;
  };

  # PRIME offload implies nvidia-drm.fbdev=1 on drivers >= 545, and that framebuffer
  # console keeps a reference on the dGPU, so runtime_status never leaves "active"
  # despite finegrained. The iGPU owns the console here, so drop it.
  hardware.nvidia.moduleParams."nvidia-drm".fbdev = lib.mkForce 0;

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

    # Two Wayland fixes:
    # - Qt6's client-side decoration plugin (libbradient) segfaults while building the
    #   titlebar, killing Plex at startup. Hyprland draws its own borders anyway.
    # - Plex sets its Wayland app_id to tv.plex.Plex, which matches no desktop entry, so
    #   the shell can't pair the window with an icon. The entry basename must equal app_id.
    (symlinkJoin {
      name = "plex-desktop-wayland";
      paths = [plex-desktop];
      nativeBuildInputs = [makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/plex-desktop \
          --set QT_WAYLAND_DISABLE_WINDOWDECORATION 1

        mv $out/share/applications/plex-desktop.desktop \
          $out/share/applications/tv.plex.Plex.desktop
      '';
    })
    telegram-desktop
    caffeine-ng
    bitwarden-desktop
  ];

  services.logind.settings.Login.HandleLidSwitch = "hibernate";

  # Lid open resumes via a full boot; skip the systemd-boot picker (hold a key to show it).
  boot.loader.timeout = 0;

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
