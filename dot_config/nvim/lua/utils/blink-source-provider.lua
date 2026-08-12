local types = require("blink.cmp.types")

local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  return self
end

function source:enabled()
  return true
end

function source:get_trigger_characters()
  return {}
end

function source:get_completions(ctx, callback)
  local fullpath = vim.api.nvim_buf_get_name(ctx.bufnr)
  local filename = fullpath ~= "" and vim.fn.fnamemodify(fullpath, ":t:r") or ""
  if filename == "" then
    callback({ items = {}, is_incomplete_backward = false, is_incomplete_forward = false })
    return
  end

  local item = {
    label = filename,
    kind = types.CompletionItemKind.File,
    detail = "current filename",
  }

  callback({
    items = { item },
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  })
end

return source
