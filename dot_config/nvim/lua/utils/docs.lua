local docs = {}

local Markdown = require("noice.text.markdown")
local require = require("noice.util.lazy")

local Config = require("noice.config")
local Format = require("noice.lsp.format")
local Hacks = require("noice.util.hacks")
local Message = require("noice.message")

function docs.setup() end

function docs.get_space_indent(line)
  local space_indent = line:match("^(%s*)")
  local count = 0
  for c in space_indent:gmatch(".") do
    if c == " " then
      count = count + 1
    else
      break -- 공백 아닌 문자 (예: \t) 만나면 종료
    end
  end
  return count
end

function docs.prettify_detail(detail, opts)
  opts = opts or {
    trim = true,
  }
  detail = detail or ""

  local result_lines = {}
  local in_code_block = false

  local indent_line_start_idx = 1
  for line in detail:gmatch("([^\r\n]*)[\r\n]?") do
    local trimmed_line = opts.trim and line:gsub("^%s*(.-)%s*$", "%1") or line

    local code_block_index = trimmed_line:find("```")

    if code_block_index then
      in_code_block = not in_code_block

      if in_code_block then
        local before = line:sub(1, code_block_index - 1)
        local after = line:sub(code_block_index)

        if before:match("%S") then
          table.insert(result_lines, before)
        end
        table.insert(result_lines, after)
      else
        table.insert(result_lines, line)
      end
    elseif in_code_block then
      table.insert(result_lines, line)
    else
      if line:match("^Auto%s+(.+)$") then
        indent_line_start_idx = indent_line_start_idx + 2
        local imported = line:match("^Auto%s+(.+)$")
        line = " " .. imported
        line = line:gsub("^%s*(.-)%s*$", "%1")
        table.insert(result_lines, line)
        table.insert(result_lines, "")
      else
        line = line:gsub("^%s*%(alias%)", "")
        line = line:gsub("^import.+$", "")
        line = line:gsub("^export.+$", "")
        if opts.trim then
          line = line:gsub("^%s*(.-)%s*$", "%1")
        end
        table.insert(result_lines, line)
      end
    end
  end

  while #result_lines > 0 and result_lines[1]:match("^%s*$") do
    table.remove(result_lines, 1)
  end

  while #result_lines > 0 and result_lines[#result_lines]:match("^%s*$") do
    table.remove(result_lines, #result_lines)
  end

  local indent = #result_lines >= indent_line_start_idx
      and docs.get_space_indent(result_lines[indent_line_start_idx])
    or 0

  for i, line in ipairs(result_lines) do
    local line_indent = docs.get_space_indent(line)
    local removed_indent = math.min(indent, line_indent)
    if removed_indent > 0 then
      result_lines[i] = line:sub(removed_indent + 1)
    end
  end

  return table.concat(result_lines, "\n")
end

return docs
