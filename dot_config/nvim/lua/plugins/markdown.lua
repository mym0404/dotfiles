local ft = { "markdown", "markdown.mdx", "mdx", "Avante", "help", "text", "txt" }

return {

  {
    -- Make sure to set this up properly if you have lazy=true
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = true,
    opts = {
      file_types = ft,
      completions = {
        blink = { enabled = true },
        lsp = { enabled = true },
      },
      render_modes = { "n", "c", "t" },
      preset = "none",
      win_options = {
        -- Window options to use that change between rendered and raw view.
        -- @see :h 'conceallevel'
        conceallevel = {
          -- Used when not being rendered, get user setting.
          default = vim.o.conceallevel,
          -- Used when being rendered, concealed text is completely hidden.
          rendered = 2,
        },
        -- @see :h 'concealcursor'
        concealcursor = {
          -- Used when not being rendered, get user setting.
          default = vim.o.concealcursor,
          -- Used when being rendered, show concealed text in all modes.
          rendered = "",
        },
      },
      patterns = {
        markdown = {
          disable = true,
          directives = {
            { id = 17, name = "conceal_lines" },
            { id = 18, name = "conceal_lines" },
          },
        },
      },
      anti_conceal = {
        enabled = true,
        ignore = {
          code_background = false,
          sign = false,
        },
        above = 0,
        below = 0,
      },
      heading = {
        enabled = true,
        render_modes = false,
        atx = true,
        setext = true,
        sign = true,
        icons = {
          "✨ ",
          "✨✨ ",
          "✨✨✨ ",
          "✨✨✨✨ ",
          "✨✨✨✨✨ ",
          "✨✨✨✨✨✨ ",
        },
        position = "overlay",
        signs = { "󰫎 " },
        width = "full",
        left_margin = 0,
        left_pad = 2,
        right_pad = 0,
        min_width = 0,
        border = true,
        border_virtual = true,
        border_prefix = false,
        above = "▄",
        below = "▀",
        backgrounds = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH3Bg",
          "RenderMarkdownH4Bg",
          "RenderMarkdownH5Bg",
          "RenderMarkdownH6Bg",
        },
        foregrounds = {
          "RenderMarkdownH1",
          "RenderMarkdownH2",
          "RenderMarkdownH3",
          "RenderMarkdownH4",
          "RenderMarkdownH5",
          "RenderMarkdownH6",
        },
        custom = {},
      },
      code = {
        enabled = true,
        render_modes = false,
        sign = true,
        style = "full",
        position = "left",
        language_pad = 1,
        language_icon = true,
        language_name = true,
        language_info = true,
        disable_background = { "diff" },
        width = "full",
        left_margin = 0,
        left_pad = 0,
        right_pad = 0,
        min_width = 0,
        border = "thin",
        language_border = "█",
        language_left = "",
        language_right = "",
        above = "▄",
        below = "▀",
        inline_left = "",
        inline_right = "",
        inline_pad = 0,
        highlight = "RenderMarkdownCode",
        highlight_info = "RenderMarkdownCodeInfo",
        highlight_language = nil,
        highlight_border = "RenderMarkdownCodeBorder",
        highlight_fallback = "RenderMarkdownCodeFallback",
        highlight_inline = "RenderMarkdownCodeInline",
      },
    },
    ft = ft,
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Markdown Preview",
      },
    },
    config = function()
      vim.cmd([[do FileType]])
    end,
  },
}
