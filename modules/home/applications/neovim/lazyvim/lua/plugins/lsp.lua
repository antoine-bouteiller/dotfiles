-- Only run a project's own oxc binary; never a global fallback.
local function project_oxc(name)
  local bin = "node_modules/.bin/" .. name
  return {
    mason = false,
    cmd = function(dispatchers, config)
      return vim.lsp.rpc.start({ vim.fs.joinpath(config.root_dir, bin), "--lsp" }, dispatchers)
    end,
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, function(_, path)
        return vim.fn.executable(vim.fs.joinpath(path, bin)) == 1
      end)
      if root then
        on_dir(root)
      end
    end,
  }
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Formatting runs every capable client; with oxfmt attached, svelte or tsgo would overwrite its output.
      format = {
        filter = function(client)
          return client.name == "oxfmt" or #vim.lsp.get_clients({ bufnr = 0, name = "oxfmt" }) == 0
        end,
      },
      servers = {
        -- lspconfig's `tsgo` is a deprecated alias of `tsc`, and `tsc` prefers a project's
        -- node_modules TypeScript, which lacks `--lsp` before 7.
        tsgo = { enabled = false },
        tsc = { mason = false, cmd = { vim.g.nix_tsc, "--lsp", "--stdio" } },
        ty = { mason = false },
        ruff = { mason = false },
        jsonls = { mason = false },
        yamlls = { mason = false },
        svelte = { mason = false },
        oxlint = project_oxc("oxlint"),
        oxfmt = project_oxc("oxfmt"),
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "svelte" } },
  },
  {
    "folke/noice.nvim",
    -- Auto-hover on blank positions would otherwise notify "No information available".
    opts = { lsp = { hover = { silent = true } } },
  },
}
