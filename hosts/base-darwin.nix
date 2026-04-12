{...}: {
  imports = [
    ./base.nix
  ];

  system.defaults.CustomUserPreferences = {
    "com.brave.Browser" = {
      BraveRewardsDisabled = true;
      BraveWalletDisabled = true;
      BraveVPNDisabled = true;
      BraveAIChatEnabled = false;
      BraveNewsDisabled = true;
      BraveTalkDisabled = true;
      TorDisabled = true;
      DnsOverHttpsMode = "automatic";
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    global = {
      autoUpdate = true;
    };
    casks = [
      # Development Tools
      "orbstack"
      "beekeeper-studio"
      "yaak"
      "ghostty"

      # Productivity Tools
      "sol"

      # Browsers
      "zen"
      "brave-browser"

      # Utility Tools
      "unnaturalscrollwheels"
      "rectangle"
      "caffeine"

      # Entertainment Tools
      "spotify"
    ];
    greedyCasks = true;
    masApps = {
      "runcat" = 1429033973;
    };
  };
}
