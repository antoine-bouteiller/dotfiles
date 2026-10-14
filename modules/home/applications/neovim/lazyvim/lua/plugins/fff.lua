return {
  {
    dir = vim.g.nix_fff_dir,
    name = "fff",
    lazy = false,
    opts = {},
    keys = {
      { "<leader><space>", function() require("fff").find_files() end, desc = "Find Files (fff)" },
      { "<leader>ff", function() require("fff").find_files() end, desc = "Find Files (fff)" },
      { "<leader>/", function() require("fff").live_grep() end, desc = "Grep (fff)" },
      { "<leader>sg", function() require("fff").live_grep() end, desc = "Grep (fff)" },
      { "<leader>sw", function() require("fff").live_grep_under_cursor() end, mode = { "n", "x" }, desc = "Grep Word (fff)" },
    },
  },
}
