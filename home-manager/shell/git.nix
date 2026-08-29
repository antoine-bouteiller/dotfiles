{
  config,
  globals,
  lib,
  ...
}: let
  signingKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
  allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";

  palette = import ../../lib/palette.nix {inherit lib;};
  inherit (palette) colors mix;
  # delta paints whole lines, so these stay mostly base; any more accent and the
  # syntax highlighting on top stops being readable. Emph is the changed words.
  diff = {
    minus = mix colors.base colors.red 0.8;
    minusEmph = mix colors.base colors.red 0.6;
    plus = mix colors.base colors.green 0.8;
    plusEmph = mix colors.base colors.green 0.6;
    hunkHeader = mix colors.base colors.mauve 0.8;
  };
in {
  home.activation.gitAllowedSigners = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f ${lib.escapeShellArg signingKeyPath} ]; then
      mkdir -p ${lib.escapeShellArg (dirOf allowedSignersFile)}
      printf '%s namespaces="git" %s\n' ${lib.escapeShellArg globals.email} "$(cat ${lib.escapeShellArg signingKeyPath})" > ${lib.escapeShellArg allowedSignersFile}
    fi
  '';

  programs.git = {
    enable = true;
    ignores = [
      # Editor
      "*.swp"
      "*~"
      ".vscode/"
      ".idea/"
      ".zed/"

      # OS
      ".DS_Store"
      "Thumbs.db"

      # Nix
      "result"
      "result-*"

      # Direnv
      ".direnv/"

      # Node
      "node_modules/"

      # Claude
      ".claude/settings.local.json"
      ".plan/"
    ];
    lfs = {
      enable = true;
      skipSmudge = true;
    };
    settings = {
      user = {
        inherit (globals) name;
        email = lib.mkDefault globals.email;
      };
      init.defaultBranch = "main";
      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
      };
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
      };
      commit = {
        gpgsign = true;
        verbose = true;
      };
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "-version:refname";
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = allowedSignersFile;
      user.signingkey = signingKeyPath;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      dark = true;
      line-numbers = true;
      navigate = true;
      # delta can only name bat's themes and bat ships no Catppuccin; Dracula is
      # the closest stock dark one.
      syntax-theme = "Dracula";

      file-style = colors.text;
      file-decoration-style = "${colors.overlay0} ul";
      hunk-header-style = "file line-number syntax";
      hunk-header-decoration-style = diff.hunkHeader;
      hunk-header-file-style = diff.hunkHeader;
      hunk-header-line-number-style = diff.hunkHeader;

      line-numbers-left-style = colors.overlay0;
      line-numbers-right-style = colors.overlay0;
      line-numbers-zero-style = colors.overlay0;
      line-numbers-minus-style = "bold ${colors.red}";
      line-numbers-plus-style = "bold ${colors.green}";

      minus-style = "syntax ${diff.minus}";
      minus-emph-style = "bold syntax ${diff.minusEmph}";
      plus-style = "syntax ${diff.plus}";
      plus-emph-style = "bold syntax ${diff.plusEmph}";

      blame-palette = "${colors.base} ${colors.mantle} ${colors.crust} ${colors.surface0} ${colors.surface1}";
    };
  };

  programs.zsh.shellAliases = {
    # --- The Basics ---
    g = "git";
    gst = "git status";
    gd = "git diff";
    ga = "git add";
    gaa = "git add --all";

    # --- Commits (The 'gc' family) ---
    gc = "git commit -v";
    "gc!" = "git commit -v --amend";
    gca = "git commit -v -a";
    "gca!" = "git commit -v -a --amend";
    "gcan!" = "git commit -v -a --no-edit --amend";
    gcam = "git commit -a -m";
    "gcam!" = "git commit -a --amend";
    gcmsg = "git commit -m";

    # --- Branches & Checkout ---
    gb = "git branch";
    gbd = "git branch -d";
    gbD = "git branch -D";
    gco = "git checkout";
    gcb = "git checkout -b";

    # --- Fetch & Rebase ---
    gf = "git fetch";
    grb = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase -i";

    # --- Cherry-pick ---
    gcp = "git cherry-pick";
    gcpa = "git cherry-pick --abort";
    gcpc = "git cherry-pick --continue";

    # --- Push & Pull ---
    gp = "git push";
    gpf = "git push --force-with-lease";
    "gpf!" = "git push --force";
    gl = "git pull";
    gpr = "git pull --rebase";
    gpra = "git pull --rebase --autostash";

    # --- Logs & Show ---
    glo = "git log --oneline --decorate";
    glg = "git log --stat";
    glog = "git log --oneline --decorate --graph";
    gsh = "git show";
    gclean = "git fetch -p && for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == \"[gone]\" {sub(\"refs/heads/\", \"\", $1); print $1}'); do git branch -D $branch; done";
  };
}
