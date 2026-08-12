local utils = require("utils/utils")

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    -- "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  opts = {
    keys = {
      { "K", false },
    },
    inlay_hints = { enabled = false },
    servers = {
      sourcekit = {
        enabled = utils.is_mac,
        settings = {},
      },
      jdtls = {},
      biome = {
        enabled = true,
      },
      eslint = { enabled = true },
      -- kotlin_language_server = {},
      vtsls = {
        enabled = true,
        settings = {
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
            preferences = {
              importModuleSpecifierPreference = "relative",
              jsxAttributeCompletionStyle = "braces",
              quotePreference = "single",
              includeCompletionsForModuleExports = true,
              importModuleSpecifierEnding = "auto",
            },
          },
        },
      },
      marksman = {
        filetypes = { "markdown", "markdown.mdx" },
        -- on_attach = function(client, bufnr)
        --   -- Disable diagnostics for markdown files
        --   vim.diagnostic.enable(false, { bufnr = bufnr })
        -- end,
      },
    },
    setup = {
      -- eslint = function()
      -- automatically fix linting errors on save (but otherwise do not format the document)
      -- vim.cmd([[
      --   autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js EslintFixAll
      -- ]])
      -- end,
      ["*"] = function(server, config)
        local lspconfig = require("lspconfig")
        local capabilities = config.capabilities

        -- apply blink lsp capabilities
        capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

        lspconfig[server].setup({ capabilities = capabilities })
      end,
    },
  },
}
