{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
  ];

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
  ];

  # nix-darwin has no programs.nh module, so run nh's cleanup as a launchd daemon
  environment.systemPackages = [pkgs.nh];
  launchd.daemons.nh-clean = {
    command = "${lib.getExe pkgs.nh} clean all --keep 2 --keep-one";
    serviceConfig = {
      RunAtLoad = false;
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        }
      ];
    };
  };

  launchd.user.agents.wallpaper = {
    script = ''
      /usr/bin/osascript -l JavaScript <<'JXA'
      ObjC.import("AppKit");
      const directory = "${../modules/home/desktop/wallpapers}";
      const files = ObjC.deepUnwrap($.NSFileManager.defaultManager.contentsOfDirectoryAtPathError(directory, null));
      const image = $.NSURL.fileURLWithPath(directory + "/" + files[Math.floor(Math.random() * files.length)]);
      const screens = $.NSScreen.screens;
      for (let i = 0; i < screens.count; i++) {
        const error = Ref();
        if (!$.NSWorkspace.sharedWorkspace.setDesktopImageURLForScreenOptionsError(image, screens.objectAtIndex(i), $({}), error)) {
          throw new Error(ObjC.unwrap(error[0].localizedDescription));
        }
      }
      JXA
    '';
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 1800;
      LimitLoadToSessionType = "Aqua";
    };
  };

  # Both the system manual and the uninstaller's embedded system eval build
  # darwin-manual-html, which fails on current nixpkgs (nixos-render-docs
  # dropped --toc-depth; nix-darwin master not yet fixed). Re-enable once
  # nix-darwin passes --sidebar-depth. Uninstaller stays available via
  # `nix run nix-darwin#darwin-uninstaller`.
  documentation.doc.enable = false;
  system.tools.darwin-uninstaller.enable = false;
  security.pam.services.sudo_local.touchIdAuth = true;

  homebrew = {
    enable = true;
    enableZshIntegration = false;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    global = {
      autoUpdate = true;
    };

    brews = [
      "coreutils"
      "mole"
    ];

    casks = [
      # Development Tools
      "orbstack"
      "ghostty"
      "zed"
      "dbx"

      # Productivity Tools
      "sol"
      "caffeine"

      # Browsers
      "helium-browser"

      # Utility Tools
      "unnaturalscrollwheels"

      "spotify"
    ];
    greedyCasks = true;
    masApps = {
      "runcat" = 6757801838;
      "bitwarden" = 1352778147;
    };
  };
}
