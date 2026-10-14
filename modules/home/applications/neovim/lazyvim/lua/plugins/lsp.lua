return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- lspconfig's `tsgo` is a deprecated alias of `tsc`, and `tsc` prefers a project's
        -- node_modules TypeScript, which lacks `--lsp` before 7.
        tsgo = { enabled = false },
        tsc = { mason = false, cmd = { vim.g.nix_tsc, "--lsp", "--stdio" } },
        ty = { mason = false },
        ruff = { mason = false },
        jsonls = { mason = false },
        yamlls = { mason = false },
      },
    },
  },
  {
    "folke/noice.nvim",
    -- Auto-hover on blank positions would otherwise notify "No information available".
    opts = { lsp = { hover = { silent = true } } },
  },
}
