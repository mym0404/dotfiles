return {
  "kevinhwang91/nvim-ufo",
  event = "VeryLazy",
  dependencies = {
    "kevinhwang91/promise-async",
  },
  opts = {
    provider_selector = function(_, filetype, _)
      if filetype == "swift" then
        return { "treesitter", "indent" }
      end
      return { "lsp", "indent" }
    end,
    open_fold_hl_timeout = 500,
    close_fold_kinds_for_ft = {
      default = {
        -- "imports",
      },
    },
    fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local lineCount = endLnum - lnum + 1

      -- Check if the first line contains a region pattern or import statement
      local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
      local regionName = line:match("#region%s+(.+)") or line:match("//region%s+(.+)")
      local isImport = line:match("^%s*import%s")

      if regionName then
        local cleanRegionName = regionName:gsub("^%s*(.-)%s*$", "%1")
        local suffix = ("▼ %s "):format(cleanRegionName, lineCount)
        local linesSuffix = ("(%d lines)"):format(lineCount)
        table.insert(newVirtText, { suffix, "FoldedBold" })
        table.insert(newVirtText, { linesSuffix, "@code.folded_line_token" })
        return newVirtText
      elseif isImport then
        local linesSuffix = ("... (%d lines)"):format(lineCount)
        table.insert(newVirtText, { "import ", "Keyword" })
        table.insert(newVirtText, { linesSuffix, "@code.folded_line_token" })
        return newVirtText
      end

      -- For non-regions, use the original text processing
      local suffix = ("... (%d lines)"):format(lineCount)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth

      local curWidth = 0
      for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          table.insert(newVirtText, { chunkText, hlGroup })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          -- str width returned from truncate() may less than 2nd argument, need padding
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end

      table.insert(newVirtText, { " ", "Folded" })
      table.insert(newVirtText, { suffix, "@code.folded_line_token" })
      return newVirtText
    end,
  },
}
