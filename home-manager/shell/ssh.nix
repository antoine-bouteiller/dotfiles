{config, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "${config.home.homeDirectory}/.ssh/config_external"
    ];
    matchBlocks = {
      "*" = {
        sendEnv = ["LANG" "LC_*"];
        hashKnownHosts = true;
      };
    };
  };
}
