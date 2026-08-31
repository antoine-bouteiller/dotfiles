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

  local.nixos.desktop.enable = true;
  local.nixos.gaming.enable = true;
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
  # card drops to D3cold when unused.
  hardware.nvidia.powerManagement.finegrained = true;

  # RTD3 support is reported by the GSP firmware's static config (bIsGc6Rtd3Allowed in
  # kernel_gsp.c), and Turing GSP firmware forbids it -- hence the 595 README's "RTD3 is
  # only supported on Ampere and above" note for the open modules, which always run GSP.
  # With GSP active the driver reports "Runtime D3 status: Not supported" regardless of
  # any NVreg_* option. RTD3 on this Turing card needs the proprietary module in
  # non-GSP mode, which is what Arch/omarchy ran when the card powered down.
  # nixos-hardware's turing profile picks open at priority 990, so a plain false wins.
  hardware.nvidia.open = false;

  # gsp.enable defaults to true for drivers >= 555, which installs the GSP firmware, and
  # the proprietary driver's default policy (EnableGpuFirmware=18) then turns GSP on for
  # Turing+. Disable both so the RM runs monolithic and RTD3 comes back.
  hardware.nvidia.gsp.enable = false;
  hardware.nvidia.moduleParams.nvidia.NVreg_EnableGpuFirmware = 0;

  # On proprietary, VRAM survives suspend/hibernate via
  # NVreg_PreserveVideoMemoryAllocations=1 plus the nvidia-suspend/hibernate/resume
  # units, which is exactly what powerManagement.enable wires up. The "595 dropped
  # /proc/driver/nvidia/suspend" hibernate failure was an open-module symptom: only open
  # drops that interface, in favor of UseKernelSuspendNotifiers, which is open-only.
  hardware.nvidia.powerManagement.enable = true;

  # fbdev=1 (the NixOS default, since PRIME offload implies it on drivers >= 545) makes
  # nvidia-drm try to build a framebuffer on a card with no CRTCs, which logs a harmless
  # "No compatible format found" every boot. Forcing 0 silences that. It is unrelated to
  # RTD3 (verified with fbdev at both 0 and 1).
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
