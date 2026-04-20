{
  osConfig,
  lib,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    programs.plasma = {
      enable = true;

      workspace = {
        clickItemTo = "select";
        lookAndFeel = "org.kde.breezedark.desktop";
        iconTheme = "Papirus-Dark";
      };

      fonts = {
        general = {
          family = "Inter";
          pointSize = 10;
        };
        menu = {
          family = "Inter";
          pointSize = 10;
        };
        toolbar = {
          family = "Inter";
          pointSize = 10;
        };
      };

      kwin = {
        titlebarButtons.left = ["close" "minimize" "maximize"];
        titlebarButtons.right = [];
        effects = {
          magicLamp.enable = true;
          overview.enable = true;
        };
      };

      panels = [
        {
          location = "top";
          height = 28;
          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.appmenu" # Global Menu
            "org.kde.plasma.panelspacer" # Left Spacer
            "org.kde.plasma.digitalclock" # Center Clock
            "org.kde.plasma.panelspacer" # Right Spacer
            "org.kde.plasma.systemtray"
          ];
        }
        # Bottom Floating Dock
        {
          location = "bottom";
          alignment = "center";
          floating = true;
          hiding = "dodgewindows";
          lengthMode = "fit";
          height = 44;
          widgets = [
            "org.kde.plasma.icontasks" # Icons-only task manager
          ];
        }
      ];
    };
  };
}
