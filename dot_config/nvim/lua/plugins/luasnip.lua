return {
  "L3MON4D3/LuaSnip",
  lazy = true,
  build = (not LazyVim.is_win())
      and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp"
    or nil,
  dependencies = {
    {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").lazy_load({
          paths = { vim.fn.stdpath("config") .. "/snippets" },
        })
      end,
    },
  },
  opts = {
    history = true,
    delete_check_events = "TextChanged",
    load_ft_func = function(bufnr)
      local ft = vim.bo[bufnr].filetype
      local is_react = ft == "javascript"
        or ft == "typescript"
        or ft == "javascriptreact"
        or ft == "typescriptreact"
      local is_swift = ft == "swift"

      if is_react then
        return { "js" }
      elseif is_swift then
        return { "swift" }
      else
        return require("luasnip.extras.filetype_functions").from_filetype_load(bufnr)
      end
    end,
  },
}
