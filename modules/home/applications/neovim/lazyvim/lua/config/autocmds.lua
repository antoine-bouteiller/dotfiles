-- Autocmds are automatically loaded on the VeryLazy event.

-- Show LSP hover docs when the cursor pauses on a symbol.
vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("auto_hover", { clear = true }),
  callback = function(ev)
    if vim.fn.mode() ~= "n" then
      return
    end
    -- Don't replace an open float, e.g. a diagnostic or the hover itself.
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
      end
    end
    if #vim.lsp.get_clients({ bufnr = ev.buf, method = "textDocument/hover" }) > 0 then
      vim.lsp.buf.hover()
    end
  end,
})
