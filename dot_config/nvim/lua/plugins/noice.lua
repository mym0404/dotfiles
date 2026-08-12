return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    enabled = true,
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = false,
        },
        -- cmdline = {
        --   opts = {},
        -- },
        -- messages = {
        --   enabled = true,
        -- },
        popupmenu = { enabled = true },
        hover = {
          silent = true,
          enabled = false,
        },
        documentation = {
          enabled = false,
          silent = true,
          view = "hover",
          ---@type NoiceViewOptions
          opts = {
            -- border = {
            --   style = "rounded",
            --   padding = { 0, 1 },
            -- },
            -- buf_options = { filetype = "markdown" },
            -- win_options = { concealcursor = "n", conceallevel = 3, wrap = true },
            -- lang = "markdown",
            -- replace = true,
            -- render = "markdown",
            -- format = { "{message}" },
          },
        },
        signature = {
          enabled = false,
          auto_open = {
            enabled = true,
            trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
            luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
            throttle = 50, -- Debounce lsp signature help request by 50ms
          },
          view = nil,
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
        {
          filter = {
            any = {
              { event = "notify", find = "No formatter available" },
              { event = "notify", find = ".*Spawning language server with cmd:.*" },
              { event = "notify", find = "Invalid server name" },
              { event = "notify", find = "Please set keymaps via the" },
            },
          },
          opts = { skip = true },
        },
      },
      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = false,
        -- inc_rename = true,
        lsp_doc_border = false,
      },
      markdown = {
        hover = {
          ["|(%S-)|"] = vim.cmd.help, -- vim help links
          ["%[.-%]%((%S-)%)"] = require("noice.util").open, -- markdown links
        },
        highlights = {
          ["|%S-|"] = "@text.reference",
          ["@%S+"] = "@parameter",
          ["^[%s@-]*param:"] = "@text.title",
          ["^[%s@-]*(Parameters:)"] = "@text.title",
          ["^[%s@-]*(Return:)"] = "@text.title",
          ["^[%s@-]*(See also:)"] = "@text.title",
          ["{%S-}"] = "@parameter",
        },
      },
    },
    keys = {
      { "<leader>sn", false },
      { "<S-Enter>", false },
      { "<leader>snl", false },
      { "<leader>snh", false },
      { "<leader>sna", false },
      { "<leader>snd", false },
      { "<leader>snt", false },
      -- {
      --   "<c-f>",
      --   function()
      --     if not require("noice.lsp").scroll(4) then
      --       return "<c-f>"
      --     end
      --   end,
      --   silent = true,
      --   expr = true,
      --   desc = "Scroll Forward",
      --   mode = { "i", "n", "s" },
      -- },
      -- {
      --   "<c-b>",
      --   function()
      --     if not require("noice.lsp").scroll(-4) then
      --       return "<c-b>"
      --     end
      --   end,
      --   silent = true,
      --   expr = true,
      --   desc = "Scroll Backward",
      --   mode = { "i", "n", "s" },
      -- },
    },
    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end
      require("noice").setup(opts)
      require("utils/docs").setup()
    end,
  },
}
