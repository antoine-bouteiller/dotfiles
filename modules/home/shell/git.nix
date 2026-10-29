{
  config,
  globals,
  lib,
  ...
}: let
  signingKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
  allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
  worktreesDir = lib.escapeShellArg config.local.home-manager.git.worktreesDir;

  palette = import ../../../lib/palette.nix {inherit lib;};
  inherit (palette) colors mix;
  # delta paints whole lines, so these stay mostly background; any more accent and the
  # syntax highlighting on top stops being readable. Emph is the changed words.
  diff = {
    minus = mix colors.background colors.red 0.8;
    minusEmph = mix colors.background colors.red 0.6;
    plus = mix colors.background colors.green 0.8;
    plusEmph = mix colors.background colors.green 0.6;
  };
in {
  options.local.home-manager.git.worktreesDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/Workspace/worktrees";
    description = "Root directory for worktrees created by the wt shell functions.";
  };

  config = {
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
          inherit (globals) name email;
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
          gpgsign = false;
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

    programs.gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };

    # Git defaults LESS to FRX when unset. -X keeps less off the alternate screen, so herdr
    # scrolls its own scrollback instead of turning the wheel into arrow keys.
    home.sessionVariables.LESS = "-FR";

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        dark = true;
        line-numbers = true;
        navigate = true;
        # Syntax highlighting uses bat's stock Dracula theme.
        syntax-theme = "Dracula";

        file-style = colors.text;
        file-decoration-style = "${colors.textFaint} ul";
        hunk-header-style = "file line-number syntax";
        hunk-header-decoration-style = "${colors.surfaceHover} box";
        hunk-header-file-style = colors.magenta;
        hunk-header-line-number-style = colors.textFaint;

        line-numbers-left-style = colors.textFaint;
        line-numbers-right-style = colors.textFaint;
        line-numbers-zero-style = colors.textFaint;
        line-numbers-minus-style = "bold ${colors.red}";
        line-numbers-plus-style = "bold ${colors.green}";

        minus-style = "syntax ${diff.minus}";
        minus-emph-style = "bold syntax ${diff.minusEmph}";
        plus-style = "syntax ${diff.plus}";
        plus-emph-style = "bold syntax ${diff.plusEmph}";

        blame-palette = "${colors.background} ${colors.backgroundDim} ${colors.backgroundDark} ${colors.surface} ${colors.surfaceRaised}";
      };
    };

    programs.zsh.initContent = ''
      # Worktree path: <worktreesDir>/<project_name>/<worktree_name>/<project_name>, keeping the
      # repo basename so wt_path resolves the same project from inside a worktree.
      wt_path() {
          local branch_name project_root project_name
          branch_name="$1"
          project_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
              echo "Not inside a git repository." >&2
              return 1
          }
          project_name=$(basename "$project_root")
          echo ${worktreesDir}"/$project_name/$branch_name/$project_name"
      }

      wt() {
          local branch_name base_ref target_path
          branch_name="$1"
          base_ref="''${2:-develop}"

          target_path="$(wt_path "$branch_name")" || return 1

          local_exists=$(git show-ref --verify --quiet "refs/heads/$branch_name"; echo $?)
          remote_exists=$(git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; echo $?)

          if [ $local_exists -eq 0 ] || [ $remote_exists -eq 0 ]; then
              echo "Branch '$branch_name' already exists. Using existing branch..."
              git worktree add "$target_path" "$branch_name"
          else
              echo "Creating new branch '$branch_name' from '$base_ref'..."
              git worktree add -b "$branch_name" "$target_path" "$base_ref"
          fi
      }

      wtr() {
          local target_dir

          target_dir="$(wt_path "$1")" || return 1

          git fetch origin "$1" && git worktree add --detach "$target_dir" "origin/$1"
      }

      # Emit "<name>\t<path>" for every worktree registered with git, regardless of
      # layout. Name is the branch (without refs/heads/), or the dir basename when detached.
      _wt_list() {
          git worktree list --porcelain 2>/dev/null | awk '
              function flush() {
                  if (path != "") {
                      name = branch
                      if (name == "") { n = split(path, a, "/"); name = a[n] }
                      print name "\t" path
                  }
                  path = ""; branch = ""
              }
              /^worktree /  { flush(); path = substr($0, 10) }
              /^branch /    { branch = $2; sub("refs/heads/", "", branch) }
              END           { flush() }
          '
      }

      _wt_resolve() {
          _wt_list | awk -F'\t' -v n="$1" '$1 == n { print $2; exit }'
      }

      wtrm() {
          local target_dir
          target_dir="$(_wt_resolve "$1")"
          [ -n "$target_dir" ] || { echo "No worktree named '$1'." >&2; return 1; }
          git worktree remove "$target_dir" && [ "''${2:-}" != "-k" ] && git branch -d "$1" 2>/dev/null
      }

      wtl() {
          git worktree list
      }

      wtcd() {
          local target_dir
          target_dir="$(_wt_resolve "$1")"
          [ -n "$target_dir" ] || { echo "No worktree named '$1'." >&2; return 1; }
          cd "$target_dir" || return 1
      }

      wtprune() {
          git worktree prune -v
      }

      _wt_names() {
          local -a names
          names=("''${(@f)$(_wt_list | awk -F'\t' 'NF { print $1 }')}")
          compadd -a names
      }
      compdef _wt_names wtcd wtrm
    '';

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
      gcm = "git commit -m";
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
  };
}
