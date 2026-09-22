{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  inherit (host) user;
in {
  imports =
    [../base-nixos.nix ./openrgb]
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  assertions = [
    {
      assertion = builtins.pathExists ./hardware-configuration.nix;
      message = "desktop: generate and git add hosts/desktop/hardware-configuration.nix before installing; see README.md.";
    }
  ];

  flakePath = "${config.users.users.${user}.home}/dotfiles";

  local.nixos.workstation.enable = true;
  local.nixos.gaming.enable = true;
  secureBoot.enable = true;

  environment.systemPackages = [pkgs.olympus];

  # Avoid Bluetooth sniff-mode stalls; reapply for each Pro Controller connection.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", KERNEL=="event*", ATTRS{id/bustype}=="0005", ATTRS{id/vendor}=="057e", ATTRS{id/product}=="2009", ATTRS{name}=="Pro Controller", TAG+="systemd", ENV{SYSTEMD_WANTS}+="bluetooth-no-sniff@%s{uniq}.service"
  '';

  # udev's sandbox excludes Bluetooth sockets, so run hcitool outside it.
  systemd.services."bluetooth-no-sniff@" = {
    description = "Disable Bluetooth sniff mode for controller %I";
    after = ["bluetooth.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bluez}/bin/hcitool lp %I RSWITCH";
    };
  };

  # HiDPI workaround: 3840x2400 panel at 200% display scale renders Steam's
  # CEF bootstrap UI off-center and crops it. Force Steam's own 2x scaling.
  programs.steam.package = pkgs.steam.override {
    extraEnv.STEAM_FORCE_DESKTOPUI_SCALING = "2";
  };

  # RTX 2080 SUPER (Turing): supported by the open kernel module.
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia.open = true;
  hardware.nvidia.powerManagement.enable = true;

  # Publish only connected displays as sinks so Noctalia can switch between them.
  services.pipewire.wireplumber.extraConfig."51-nvidia-dual-output" = {
    "monitor.alsa.rules" = [
      {
        matches = [{"device.name" = "alsa_card.pci-0000_01_00.1";}];
        actions.update-props = {
          "device.profile-set" = "${pkgs.writeText "nvidia-dual-output.conf" ''
            .include ${pkgs.pipewire}/share/alsa-card-profile/mixer/profile-sets/default.conf

            [General]
            auto-profiles = no

            [Profile monitor-stereo]
            description = Monitor stereo output
            output-mappings = hdmi-stereo

            [Profile tv-stereo]
            description = TV stereo output
            output-mappings = hdmi-stereo-extra1

            [Profile dual-stereo]
            description = Monitor and TV stereo outputs
            output-mappings = hdmi-stereo hdmi-stereo-extra1
          ''}";
        };
      }
    ];
    "wireplumber.components" = [
      {
        name = "nvidia-outputs.lua";
        type = "script/lua";
        # WirePlumber loads hooks.* before the event source and device monitors.
        provides = "hooks.nvidia-outputs";
      }
    ];
    "wireplumber.profiles".main."hooks.nvidia-outputs" = "required";
  };
  services.pipewire.wireplumber.extraScripts."nvidia-outputs.lua" = builtins.readFile ./nvidia-outputs.lua;

  programs.coolercontrol.enable = true;

  # Keep the OS picker visible for Windows dual boot.
  boot.loader.timeout = 5;

  system.stateVersion = "26.05";
}
