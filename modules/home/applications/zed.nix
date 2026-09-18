{
  mkModule,
  config,
  pkgs,
  lib,
  ...
} @ args:
mkModule args "local.home-manager.zed" {
  description = "Zed Editor";
  config = _: let
    fontFamily = "MesloLGM Nerd Font";
    oxfmtSettings = {
      format_on_save = "on";
      prettier.allowed = false;
      formatter = [{language_server.name = "oxfmt";}];
    };
    webLanguageSettings =
      oxfmtSettings
      // {
        language_servers = ["!tailwindcss-language-server" "..."];
      };
    typescriptSettings =
      oxfmtSettings
      // {
        language_servers = ["typescript-ls" "!vtsls" "!typescript-language-server" "!eslint" "!tailwindcss-language-server" "..."];
      };
  in {
    programs.zsh.shellAliases = lib.mkIf (config.local.home-manager.desktop.enable && !pkgs.stdenv.hostPlatform.isDarwin) {
      zed = "zeditor";
    };

    programs.zed-editor = {
      enable = true;
      # Darwin gets the editor from Homebrew.
      package = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin || !config.local.home-manager.desktop.enable) null;
      mutableUserSettings = false;
      mutableUserKeymaps = false;
      userSettings = {
        debugger.button = false;
        cli_default_open_behavior = "new_window";
        agent.enabled = false;
        project_panel.dock = "right";
        outline_panel.button = false;
        outline_panel.dock = "right";
        collaboration_panel.button = false;
        collaboration_panel.dock = "right";
        git_panel.dock = "right";
        diff_view_style = "split";
        buffer_font_family = fontFamily;
        lsp.oxlint.initialization_options.settings = {
          configPath = null;
          run = "onSave";
          disableNestedConfig = false;
          fixKind = "safe_fix";
          unusedDisableDirectives = "deny";
        };
        lsp.oxfmt.initialization_options.settings = {
          "fmt.configPath" = null;
          run = "onSave";
        };

        file_scan_exclusions = ["**/node_modules" "**/.direnv" "**/.worktree" "..."];

        languages = {
          Python.language_servers = ["!basedpyright" "ruff" "ty" "!pyrefly" "!pyright" "!pylsp" "..."];
          CSS = oxfmtSettings;
          GraphQL = oxfmtSettings;
          HTML = webLanguageSettings;
          JavaScript =
            webLanguageSettings
            // {
              formatter = oxfmtSettings.formatter ++ [{code_action = "source.fixAll.oxc";}];
            };
          JSON = oxfmtSettings;
          JSON5 = oxfmtSettings;
          JSONC = oxfmtSettings;
          Markdown = oxfmtSettings;
          MDX = oxfmtSettings;
          TypeScript = typescriptSettings;
          TSX = typescriptSettings;
          YAML = oxfmtSettings;
          Astro = {
            language_servers = ["!eslint" "!vtsls" "astro-language-server" "..."];
            code_actions_on_format = {
              "source.fixAll.eslint" = true;
              "source.organizeImports" = true;
            };
          };
          Nix = {
            language_servers = ["nixd"];
            formatter.external = {
              command = "alejandra";
              arguments = ["--quiet" "--"];
            };
          };
          TOML = {
            language_servers = [];
            format_on_save = "off";
          };
        };
        terminal = {
          button = false;
          font_family = fontFamily;
          font_size = 12;
          line_height.custom = 1.4;
        };
        minimap.show = "auto";
        autosave = "on_focus_change";
        confirm_quit = true;
        linked_edits = true;
        preferred_line_length = 160;
        base_keymap = "VSCode";
        ui_font_size = 15;
        buffer_font_size = 14;
        theme = {
          mode = "system";
          light = "Catppuccin Latte";
          dark = "Catppuccin Mocha";
        };
        icon_theme = "Material Icon Theme";
      };

      userKeymaps = [
        {
          context = "Terminal";
          bindings.shift-enter = ["terminal::SendText" (builtins.fromJSON ''"\u001b\r"'')];
        }
        {
          context = "Editor";
          bindings.cmd-shift-k = "editor::DeleteLine";
        }
        {
          context = "Editor";
          bindings."cmd-/" = [
            "editor::ToggleComments"
            {advance_downwards = false;}
          ];
        }
      ];

      extensions = [
        "astro"
        "catppuccin"
        "csharp"
        "dockerfile"
        "elisp"
        "git-firefly"
        "html"
        "json5"
        "lua"
        "material-icon-theme"
        "mdx"
        "nix"
        "nu"
        "oxc"
        "sql"
        "toml"
        "tsgo"
        "xml"
      ];
    };
  };
}
