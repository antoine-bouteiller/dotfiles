{
  host,
  inputs,
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
    schedule.weekday = null;
  };

  environment.variables = {
    NODE_OPTIONS = "--max-old-space-size=4096";
    AGENT_BROWSER_ENGINE = "lightpanda";
  };

  environment.systemPackages = with pkgs; [
    # CLI
    agent-browser
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.lightpanda
    sonarqube-cli
    glab
    yamllint
    shellcheck
    beads
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

        KeyRepeat = 2;
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = true;
        launchanim = true;
        orientation = "bottom";
        tilesize = 56;

        persistent-apps = [
          "/Applications/Slack.app/"
          "/Applications/Ghostty.app/"
          "/Applications/Helium.app/"
          "/Applications/Zed.app/"
          "/Applications/Telegram.app/"
        ];
      };

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
