return {
  "folke/flash.nvim",
  lazy = false,
  priority = 1000,
  event = "VeryLazy",
  ---@type Flash.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    search = {
      multi_window = false,
    },
    prompt = {
      enabled = false,
    },
    jump = {
      pos = "end",
      autojump = false,
      offset = 0,
    },
    label = {
      after = true,
      before = false,
    },
    highlight = {
      backdrop = false,
      matches = true,
      priority = 9999,
      groups = {
        match = "FlashMatch",
        current = "FlashCurrent",
        backdrop = "FlashBackdrop",
        label = "FlashLabel",
        cursor = "FlashCursor",
      },
    },
    modes = {
      search = {},
      char = {
        highlight = { backdrop = false },
        keys = { "f", "F" },
        jump = { pos = "start" },
      },
      treesitter = {
        label = { after = true },
        jump = { pos = "range" },
      },
      treesitter_search = {
        jump = { pos = "range" },
        label = { after = true },
        search = { multi_window = false },
      },
    },
  },
  keys = {},
  config = function(_, opts)
    require("flash").setup(opts)
    vim.keymap.set({ "n", "o", "x" }, "s", function()
      require("flash").jump({
        search = {
          mode = "search",
          multi_window = false,
        },
      })
    end, { desc = "Flash Search" })
  end,
}
