local tags = {}
for _, name in ipairs({ "p", "div", "span", "br", "a", "sup", "sub", "u", "center", "details", "summary" }) do
  tags[name] = {}
end
tags.b = { scope_highlight = "@markup.strong" }
tags.strong = tags.b
tags.i = { scope_highlight = "@markup.italic" }
tags.em = tags.i
tags.code = { scope_highlight = "@markup.raw" }

local latex_cache = {}

local function latex2text(formula)
  if latex_cache[formula] == nil then
    local out = vim.system({ vim.g.nix_latex2text }, { stdin = formula, text = true }):wait()
    latex_cache[formula] = out.code == 0 and vim.trim(out.stdout):gsub("\n", " ") or false
  end
  return latex_cache[formula]
end

-- Markdown does not parse math inside HTML blocks, so the builtin latex handler never sees it.
local function html_latex_marks(ctx)
  local marks = {}
  local query = vim.treesitter.query.parse("html", "(text) @text")
  for _, node in query:iter_captures(ctx.root, ctx.buf) do
    local start_row, start_col, end_row, end_col = node:range()
    for i, line in ipairs(vim.api.nvim_buf_get_text(ctx.buf, start_row, start_col, end_row, end_col, {})) do
      local row, offset = start_row + i - 1, i == 1 and start_col or 0
      local s = line:find("$", 1, true)
      while s do
        local pattern = line:sub(s, s + 1) == "$$" and "^%$%$(.-)%$%$" or "^%$([^$]+)%$"
        local _, e, formula = line:find(pattern, s)
        local text = formula and latex2text(formula)
        if text then
          marks[#marks + 1] = {
            conceal = true,
            start_row = row,
            start_col = offset + s - 1,
            opts = {
              end_col = offset + e,
              conceal = "",
              virt_text = { { text, "RenderMarkdownMath" } },
              virt_text_pos = "inline",
            },
          }
        end
        s = line:find("$", (e or s + 1) + 1, true)
      end
    end
  end
  return marks
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {
      html = { tag = tags },
      latex = { converter = vim.g.nix_latex2text },
      custom_handlers = { html = { extends = true, parse = html_latex_marks } },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "latex" } },
  },
}
