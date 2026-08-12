return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  -- keys = {
  --
  --     bu{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
  --   { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
  --   { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
  --   { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
  --   { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
  --   { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
  --   { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
  --   { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
  --   { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
  --   { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
  -- },
  opts = {
    options = {
      style_preset = require("bufferline").style_preset.minimal,
      name_formatter = function(buf)
        local name = buf.name
        local extensions_to_drop = {
          "mjs",
          "cjs",
          "kt",
          "jsx",
          "js",
          "tsx",
          "ts",
          "lua",
          "json",
          "md",
          "txt",
          "html",
          "css",
          "scss",
          "sass",
          "less",
          "yaml",
          "yml",
          "xml",
        }
        for _, ext in ipairs(extensions_to_drop) do
          if name:match("." .. ext .. "$") then
            return " " .. name:gsub("." .. ext .. "$", "")
          end
        end
        return " " .. name
      end,
      custom_filter = function(buf_number, buf_numbers)
        local name = vim.fn.bufname(buf_number)
        local buf = vim.bo[buf_number]
        -- exclude explorer
        if buf.filetype == "" and (name == "./" or name == "" or name == nil) then
          return false
        end
        return true
      end,
      numbers = "none",
      truncate_names = false,
      buffer_close_icon = "",
      modified_icon = "",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      always_show_bufferline = true,
      tab_size = 14,
      indicator = {
        style = "icon",
        icon = "▎",
      },
      color_icons = true,
      diagnostics = "nvim_lsp",
      diagnostics_indicator = function(count, level, diag, context)
        if level == "hint" then
          return ""
        end
        return ""
        -- return "(" .. count .. ")"
      end,
      show_buffer_icons = true,
      show_buffer_close_icons = false,
      show_close_icon = false,
      show_tab_indicators = true,
      separator_style = { "", "" },
    },
  },
  -- config = function(_, opts)
  --   require("bufferline").setup(opts)
  --   -- Fix bufferline when restoring a session
  --   vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
  --     callback = function()
  --       vim.schedule(function()
  --         pcall(nvim_bufferline)
  --       end)
  --     end,
  --   })
  -- end,
}
