return {
  "lewis6991/gitsigns.nvim",
  event = "LazyFile",
  opts = {
    signs = {
      add = { text = "❙" },
      change = { text = "❙" },
      delete = { text = "❙" },
      topdelete = { text = "❙" },
      changedelete = { text = "❙" },
      untracked = { text = "❙" },
    },
    signs_staged = {
      add = { text = "❙" },
      change = { text = "❙" },
      delete = { text = "❙" },
      topdelete = { text = "❙" },
      changedelete = { text = "❙" },
      untracked = { text = "❙" },
    },
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 500,
    },
    signcolumn = true,

    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end)
    end,
  },
}
