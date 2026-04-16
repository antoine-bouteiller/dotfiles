{
  inputs,
  globals,
  pkgs,
  config,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../home-manager/common.nix
    ../../home-manager/applications/ghostty.nix
    ../../home-manager/applications/vim.nix
    ../../home-manager/applications/zed
    ../../home-manager/applications/claude-code
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    packages = [pkgs.dockutil];
    stateVersion = "25.11";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-packages/bin"
  ];
  home.sessionVariables = {
    NODE_PATH = "${config.home.homeDirectory}/.npm-packages/lib/node_modules";
  };

  programs.git = {
    settings.user.email = "antoine.bouteiller@pelico.io";
    includes = [
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        path = "~/.gitconfig-github";
      }
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        path = "~/.gitconfig-github";
      }
    ];
  };

  home.file.".gitconfig-github" = {
    text = ''
      [user]
        email = ${globals.email}
    '';
  };

  home.file.".npmrc".text = ''
    @pelico:registry=http://nexus.pelico.best/repository/npm/
    prefix=${config.home.homeDirectory}/.npm-packages
  '';

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      github_pat = {};
      gitlab_token = {};
      azure_openai_api_key = {};
      linear_token = {};
      "deskbird/refresh_token" = {};
      "deskbird/google_api_key" = {};
    };

    templates."secrets.env" = {
      content = ''
        export GITHUB_PAT=${config.sops.placeholder.github_pat}
        export GITLAB_TOKEN=${config.sops.placeholder.gitlab_token}
        export AZURE_OPENAI_API_KEY=${config.sops.placeholder.azure_openai_api_key}
        export LINEAR_TOKEN=${config.sops.placeholder.linear_token}
        export DESKBIRD_REFRESH_TOKEN=${config.sops.placeholder."deskbird/refresh_token"}
        export DESKBIRD_GOOGLE_API_KEY=${config.sops.placeholder."deskbird/google_api_key"}
      '';
    };
  };

  programs.zsh.envExtra = ''
    # Source sops-nix decrypted secrets
    [[ -f "${config.sops.templates."secrets.env".path}" ]] && source "${config.sops.templates."secrets.env".path}"
  '';

  manual.manpages.enable = false;
}
