{
  host,
  config,
  pkgs,
  ...
}: let
  inherit (host) user;
in {
  imports = [
    ../base-darwin.nix
  ];

  flakePath = "${config.users.users.${user}.home}/.dotfiles";

  autoUpgrade = {
    enable = true;
    sshKeyPath = "${config.users.users.${user}.home}/.ssh/id_ed25519";
    schedule = {
      hour = 10;
      weekday = null;
    };
  };

  environment.variables = {
    NODE_OPTIONS = "--max-old-space-size=4096";
    AGENT_BROWSER_EXECUTABLE_PATH = "/Applications/Helium.app/Contents/MacOS/Helium";
  };

  environment.systemPackages = with pkgs; [
    # CLI
    agent-browser
    sonarqube-cli
    glab
    yamllint
    shellcheck
  ];

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  nix = {
    settings = {
      trusted-users = [
        "@admin"
        "${user}"
      ];
    };
  };

  homebrew = {
    casks = [
      "tailscale-app"
      "firefox"
      # sdkmanager; the SDK itself lives in ANDROID_HOME (home.nix)
      "android-commandlinetools"
    ];
  };

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 5;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
        AppleSpacesSwitchOnActivate = true;

        KeyRepeat = 2;
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 56;

        persistent-apps = [
          "/Applications/Slack.app/"
          "${config.users.users.${user}.home}/Applications/Home Manager Apps/Rex.app/"
          "/Applications/Helium.app/"
          "/Applications/Telegram.app/"
        ];
      };

      CustomUserPreferences."com.apple.dock"."workspaces-auto-swoosh" = true;

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
      };
    };
  };
}
