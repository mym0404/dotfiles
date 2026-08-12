local utils = require("utils/utils")

local function reset_keymaps()
  local reset_keys = {
    { "n", "gc" },
    { "n", "gco" },
    { "n", "gcO" },
    { "o", "gc" },
    { "n", "gcc" },
  }
  for _, key in ipairs(reset_keys) do
    pcall(vim.keymap.del, key[1], key[2])
  end
end

local function map_comments()
  local api = require("Comment.api")

  vim.keymap.set("n", "gc", api.toggle.linewise.current)

  -- local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)

  -- vim.keymap.set("x", "gc", function()
  --   vim.api.nvim_feedkeys(esc, "nx", false)
  --   api.toggle.linewise(vim.fn.visualmode())
  -- end)
end

local function customizeExitInsertMode()
  local keys = { "jk", "jj" }
  for _, key in ipairs(keys) do
    vim.keymap.set({ "i" }, key, function()
      vim.snippet.stop()
      return "<esc>"
    end, { expr = true, noremap = true, silent = true, desc = "Exit insert mode" })
  end
  -- for _, key in ipairs(keys) do
  --   vim.keymap.set(
  --     { "t" },
  --     key,
  --     "<Esc><Esc>",
  --     { noremap = true, silent = true, desc = "Exit insert mode" }
  --   )
  -- end
end

local function manipulate_yank_paste_register_behavior()
  -- vim.keymap.set({ "n", "v" }, "y", '"zy', { desc = "Yank to register a" })
  -- vim.keymap.set({ "n", "v" }, "p", '"zp', { desc = "Paste from register a" })
  -- vim.keymap.set(
  --   { "n", "v" },
  --   "P",
  --   '"zP',
  --   { desc = "Paste before from register a" }
  -- )
  vim.keymap.set({ "n", "v" }, "x", '"_x', { desc = "Delete without register" })
  vim.keymap.set({ "n", "v" }, "c", '"_c', { desc = "Change without register" })
  -- vim.keymap.set({ "n", "v" }, "d", '"zd', { desc = "Delete without register" })
end

local function map_esc()
  vim.keymap.set("x", "q", "<Esc>", { silent = true, desc = "Exit visual mode with q" })
  -- if blink.cmp completion menu is showing, close it or return <esc> itself
  vim.keymap.set("i", "<esc>", function()
    -- local cmp = require("blink.cmp")
    -- if cmp.is_menu_visible() then
    --   cmp.hide()
    --   return ""
    -- end
    vim.snippet.stop()
    return "<Esc>"
  end, { silent = true, expr = true })
end

local function configure_git_diff()
  vim.keymap.set(
    "n",
    "<leader>z",
    "<cmd>DiffviewOpen<cr>",
    { silent = true, desc = "Open Diff View" }
  )
  vim.keymap.set(
    "n",
    "<leader>h",
    "<cmd>DiffviewFileHistory %<cr>",
    { silent = true, desc = "Open Diff view file history" }
  )
end

-- local function map_close_tap_or_buffer()
--   vim.keymap.set("n", "<C-w>", function()
--     local tab_count = vim.fn.tabpagenr("$")
--     if tab_count > 1 then
--       vim.cmd("tabclose")
--     else
--       vim.cmd("close")
--     end
--   end, {
--     desc = "Close tab if multiple tabs, else close buffer",
--   })
-- end

local function map_git_actions()
  vim.keymap.set("n", "<leader>gr", function()
    local filepath = vim.fn.expand("%")
    if filepath == "" then
      print("No file to restore")
      return
    end
    local gs = require("gitsigns")
    gs.reset_buffer()

    filepath = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")

    vim.notify("Discarded changes in " .. filepath, vim.log.levels.INFO)
  end, { silent = true, desc = "Git discard current file changes" })

  vim.keymap.set("x", "<leader>gr", function()
    local start_line, end_line = utils.get_start_and_end_lines()
    local filepath = vim.fn.expand("%:p")

    if filepath == "" then
      print("No file to restore")
      return
    end

    local gs = require("gitsigns")
    gs.reset_hunk({ start_line, end_line })
    utils.go_to_normal_mode()
  end, { silent = true, desc = "Git restore selected lines" })
end

local function map_rename()
  vim.keymap.set("n", "<F6>", function()
    return ":IncRename " .. vim.fn.expand("<cword>")
  end, { desc = "Rename file", expr = true })
end

local function map_delete_file()
  vim.keymap.set("n", "<leader>cR", function()
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == "" then
      vim.notify("No file to rename", vim.log.levels.WARN)
      return
    end

    local current_name = vim.fn.fnamemodify(current_file, ":t")
    vim.ui.input({
      prompt = "Rename file: ",
      default = current_name,
    }, function(input)
      if input and input ~= "" and input ~= current_name then
        local new_path = vim.fn.fnamemodify(current_file, ":h") .. "/" .. input
        vim.cmd("saveas " .. vim.fn.fnameescape(new_path))
        vim.cmd("bdelete #")
        vim.fn.delete(current_file)
        vim.notify("File renamed to: " .. input, vim.log.levels.INFO)
      end
    end)
  end, { desc = "Rename current file", nowait = true })

  vim.keymap.set("n", "<leader>cd", function()
    local current_buffer_file_path = vim.api.nvim_buf_get_name(0)
    vim.cmd("bdelete")
    vim.cmd("!rm " .. current_buffer_file_path)
    vim.notify("Delete file " .. current_buffer_file_path)
  end, { desc = "Delete current file", nowait = true })
end

local function map_enter()
  vim.keymap.set({ "n", "i" }, "<cr>", function()
    local prefix = vim.api.nvim_get_mode().mode == "n" and "i" or ""
    if utils.should_be_double_new_line() then
      return prefix .. "<cr><esc>O"
    end
    return prefix .. "<cr>"
  end, { expr = true, noremap = true, nowait = true, silent = true })
end

local function map_recording()
  vim.keymap.set("n", "q", "<Nop>")
  vim.keymap.set("n", "!", "qt", { desc = "start recording with register t" })
  vim.keymap.set("n", "@", "@t", { desc = "run recording with register t" })
end

local function map_smart_splits()
  local vertical_resize_amount = 3
  local horizontal_resize_amount = 5
  -- recommended mappings
  -- resizing splits
  -- these keymaps will also accept a range,
  -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
  vim.keymap.set({ "n", "t" }, "<A-h>", function()
    require("smart-splits").resize_left(horizontal_resize_amount)
  end)
  vim.keymap.set({ "n", "t" }, "<A-j>", function()
    require("smart-splits").resize_down(vertical_resize_amount)
  end)
  vim.keymap.set({ "n", "t" }, "<A-k>", function()
    require("smart-splits").resize_up(vertical_resize_amount)
  end)
  vim.keymap.set({ "n", "t" }, "<A-l>", function()
    require("smart-splits").resize_right(horizontal_resize_amount)
  end)

  -- moving between splits
  vim.keymap.set({ "i", "n", "t" }, "<C-h>", function()
    if vim.api.nvim_get_mode().mode == "i" then
      utils.go_to_normal_mode()
    end
    require("smart-splits").move_cursor_left({ at_edge = "stop" })
  end)
  vim.keymap.set({ "i", "n", "t" }, "<C-j>", function()
    if vim.api.nvim_get_mode().mode == "i" then
      utils.go_to_normal_mode()
    end
    require("smart-splits").move_cursor_down({ at_edge = "stop" })
  end)
  vim.keymap.set({ "i", "n", "t" }, "<C-k>", function()
    if vim.api.nvim_get_mode().mode == "i" then
      utils.go_to_normal_mode()
    end
    require("smart-splits").move_cursor_up({ at_edge = "stop" })
  end)
  vim.keymap.set({ "i", "n", "t" }, "<C-l>", function()
    if vim.api.nvim_get_mode().mode == "i" then
      utils.go_to_normal_mode()
    end
    require("smart-splits").move_cursor_right({ at_edge = "stop" })
  end)

  -- vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous)
  -- swapping buffers between windows
  -- vim.keymap.set("n", "<leader><leader>h", require("smart-splits").swap_buf_left)
  -- vim.keymap.set("n", "<leader><leader>j", require("smart-splits").swap_buf_down)
  -- vim.keymap.set("n", "<leader><leader>k", require("smart-splits").swap_buf_up)
  -- vim.keymap.set("n", "<leader><leader>l", require("smart-splits").swap_buf_right)
end

local function map_split()
  vim.keymap.set("n", "_", ":split<cr>", { desc = "split horizontal", nowait = true })
  vim.keymap.set("n", "|", ":vsplit<cr>", { desc = "split vertical", nowait = true })
end

local function map_select_all()
  vim.keymap.set("n", "<c-a>", "ggVG", { desc = "select all" })
end

local function map_shift_cr()
  vim.keymap.set("i", "<S-CR>", "<esc>o")
  vim.keymap.set("n", "<S-CR>", "i<esc>o")
end

local function map_docs_hover()
  vim.keymap.set("n", "<s-d>", function()
    vim.lsp.buf.hover({
      silent = true,
      title = "🌱 Docs",
      max_width = 100,
      width = 70,
      max_height = 120,
      height = 100,
      wrap = false,
      zindex = 100,

      title_pos = "center",
      relative = "cursor",
      anchor_bias = "auto",
      border = "rounded",
    })
  end, { desc = "hover documentation", silent = true })
end

local function map_scroll()
  vim.keymap.set("n", "<C-d>", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local height = vim.api.nvim_win_get_height(0)
    local isUpmost = row < 15 or (row + 15) < (height / 2)
    return isUpmost and math.max(row + 15, math.floor(height / 2)) .. "Gzz" or "15<C-d>zz"
  end, { noremap = true, nowait = true, expr = true })

  vim.keymap.set("n", "<C-u>", function()
    return "15<C-u>zz"
  end, { noremap = true, nowait = true, expr = true })
end

local function map_hover_scroll()
  local function scroll(dir)
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(winid)
      if config.relative ~= "" then
        local bufnr = vim.api.nvim_win_get_buf(winid)
        if vim.bo[bufnr].buftype == "nofile" then
          local Util = require("noice.util")
          Util.nui.scroll(winid, dir * 4)
          return ""
        end
      end
    end

    return dir > 0 and "<C-f>" or "<C-b>"
  end

  vim.keymap.set("n", "<C-f>", function()
    return scroll(1)
  end, { expr = true, silent = true, noremap = true, desc = "Scroll down (hover or buffer)" })

  vim.keymap.set("n", "<C-b>", function()
    return scroll(-1)
  end, { expr = true, silent = true, noremap = true, desc = "Scroll up (hover or buffer)" })
end

local function configure_lsp()
  vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(opts)
      -- Skip if buffer is not writable or has special buftype
      local buftype = vim.bo[opts.buf].buftype
      if buftype ~= "" then
        return
      end

      utils.on_save_action(opts.buf, function()
        vim.cmd("silent! noautocmd write")
      end)
    end,
    nested = false,
  })

  vim.keymap.set("n", "<leader>co", function()
    utils.organize_imports(0)
  end, { desc = "Organize Import", silent = true })

  vim.keymap.set("n", "<leader>cm", function()
    utils.add_missing_imports(0)
  end, { desc = "Add Missing Imports", silent = true })

  vim.keymap.set({ "n", "i" }, "<c-x>", function()
    utils.on_save_action(0, function()
      LazyVim.format({ force = false })
      if vim.api.nvim_get_mode().mode == "i" then
        utils.go_to_normal_mode()
      end
      -- stop snippets
      vim.snippet.stop()
    end)
  end, { desc = "Format" })

  vim.keymap.set({ "n" }, "<leader>cL", function()
    vim.cmd("LspRestart")
  end, { desc = "Restart LSP" })
end

local function map_delete_buffer()
  vim.keymap.set("n", "<leader>w", function()
    utils.run_key("<leader>bd", "m")
  end, {})
end

local function map_react_prop_bracket()
  -- = to open curly brace
  vim.keymap.set("i", "=", function()
    if vim.bo.filetype ~= "typescriptreact" and vim.bo.filetype ~= "javascriptreact" then
      return "="
    end
    local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
    if
      node ~= nil
      and (node:type() == "jsx_opening_element" or node:type() == "jsx_self_closing_element")
    then
      return "={}<esc>i"
    end
    return "="
  end, { nowait = true, expr = true })

  -- / to close tag
  -- vim.keymap.set("i", "/", function()
  --   if vim.bo.filetype ~= "typescriptreact" and vim.bo.filetype ~= "javascriptreact" then
  --     return "/"
  --   end
  --   local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  --   local _, col = utils.get_row_and_col()
  --   local line = vim.api.nvim_get_current_line()
  --   local next_char = line:sub(col + 1, col + 1)
  --   local left = line:sub(1, col)
  --
  --   if not node then
  --     return "/"
  --   end
  --
  --   if node ~= nil and node:has_error() and next_char ~= ">" and left:match(".*<[%w%d]+.*") then
  --     return "/>"
  --   end
  --
  --   local tag_name = utils.get_jsx_name(node)
  --   local next_sibling = node:next_sibling()
  --   if
  --     node ~= nil
  --     and next_sibling ~= nil
  --     and tag_name ~= nil
  --     and node:type() == "jsx_opening_element"
  --     and next_char == ">"
  --     and tag_name == utils.get_jsx_name(node:next_sibling())
  --   then
  --     local start_row, start_col, end_row, end_col = next_sibling:range()
  --     vim.schedule(function()
  --       vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, {})
  --     end)
  --     return "/"
  --   end
  --
  --   return "/"
  -- end, { nowait = true, expr = true })
end

local function map_template_string()
  local Rule = require("nvim-autopairs.rule")
  local npairs = require("nvim-autopairs")
  local cond = require("nvim-autopairs.conds")
  local allowed_ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" }

  npairs.add_rule(
    Rule("{", "}", allowed_ft)
      :with_pair(cond.before_text("$"))
      :with_pair(cond.is_inside_quote())
      :replace_endpair(function(_)
        local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
        if node == nil then
          return "}"
        end
        local string_node = (node ~= nil and node:type() == "string") and node
          or (
            (node ~= nil and node:parent() ~= nil and node:parent():type() == "string")
              and node:parent()
            or nil
          )
        if string_node ~= nil then
          local start_row, start_col, end_row, end_col = string_node:range()
          vim.schedule(function()
            vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, start_col + 1, { "`" })
            vim.api.nvim_buf_set_text(0, start_row, end_col, end_row, end_col + 2, { "`" })
          end)
          return "}"
        else
          return "}"
        end
      end)
  )
  -- press x1234 => x12341234
  npairs.add_rules({
    Rule("x%d%d%d%d$", "number", "lua"):use_regex(true):replace_endpair(function(opts)
      -- print(vim.inspect(opts))
      return opts.prev_char:sub(#opts.prev_char - 3, #opts.prev_char)
    end),
  })
end

local function map_yank()
  vim.keymap.set("n", "yf", function()
    -- local absolute_path = vim.fn.expand("%:p")
    local relative_path = vim.fn.expand("%:.")
    vim.fn.setreg("+", relative_path)
    vim.notify("Copied: " .. relative_path, vim.log.levels.INFO, { title = "Copy File Path" })
  end, { desc = "copy current file path", nowait = true })

  vim.keymap.set("n", "yd", function()
    -- local absolute_dir = vim.fn.expand("%:p:h")
    local relative_dir = vim.fn.expand("%:.:h")
    vim.fn.setreg("+", relative_dir)
    vim.notify("Copied: " .. relative_dir, vim.log.levels.INFO, { title = "Copy Directory Path" })
  end, { desc = "copy current file directory path", nowait = true })

  vim.keymap.set("n", "yb", function()
    local buffers = vim.fn.getbufinfo({ buflisted = 1 })
    local relative_paths = {}
    for _, buf in ipairs(buffers) do
      if buf.name and buf.name ~= "" and vim.fn.isdirectory(buf.name) == 0 then
        local relative_path = vim.fn.fnamemodify(buf.name, ":.")
        table.insert(relative_paths, relative_path)
      end
    end
    local absolute_paths_string = table.concat(relative_paths, "\n")
    vim.fn.setreg("+", absolute_paths_string)
    vim.notify(
      "Copied: " .. #relative_paths .. " buffer paths",
      vim.log.levels.INFO,
      { title = "Copy Buffer Paths" }
    )
  end, { desc = "copy all buffer absolute paths", nowait = true })

  vim.keymap.set("n", "yl", function()
    -- local absolute_path = vim.fn.expand("%:p")
    local relative_path = vim.fn.expand("%:.")
    local line_num = vim.fn.line(".")
    -- local absolute_path_with_line = absolute_path .. ":" .. line_num
    local relative_path_with_line = relative_path .. ":" .. line_num
    vim.fn.setreg("+", relative_path_with_line)
    vim.notify(
      "Copied: " .. relative_path_with_line,
      vim.log.levels.INFO,
      { title = "Copy File with line" }
    )
  end, { desc = "copy current file with line", nowait = true })

  vim.keymap.set("v", "yl", function()
    local absolute_path = vim.fn.expand("%:p")
    local relative_path = vim.fn.expand("%:.")
    local start_line, end_line = utils.get_start_and_end_lines()
    local absolute_path_with_lines = start_line == end_line and absolute_path .. ":" .. start_line
      or absolute_path .. ":" .. start_line .. "-" .. end_line
    local relative_path_with_lines = start_line == end_line and relative_path .. ":" .. start_line
      or relative_path .. ":" .. start_line .. "-" .. end_line
    vim.fn.setreg("+", relative_path_with_lines)
    vim.notify(
      "Copied: " .. relative_path_with_lines,
      vim.log.levels.INFO,
      { title = "Copy File with line range" }
    )
    utils.go_to_normal_mode()
  end, { desc = "copy current file with line range", nowait = true })

  local function register_diagnostic_yank(command, severity_map)
    vim.keymap.set("n", command, function()
      local current_bufnr = vim.api.nvim_get_current_buf()
      local formatted_diagnostics_list = {}

      local severity_counts = {
        [vim.diagnostic.severity.ERROR] = 0,
        [vim.diagnostic.severity.WARN] = 0,
        [vim.diagnostic.severity.INFO] = 0,
        [vim.diagnostic.severity.HINT] = 0,
      }
      local severity_icons = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN] = "",
        [vim.diagnostic.severity.INFO] = "",
        [vim.diagnostic.severity.HINT] = "",
      }
      local severity_name = {
        [vim.diagnostic.severity.ERROR] = "Error",
        [vim.diagnostic.severity.WARN] = "Warning",
        [vim.diagnostic.severity.INFO] = "Info",
        [vim.diagnostic.severity.HINT] = "Hint",
      }

      local current_filetype = vim.bo[current_bufnr].filetype
      local js_filetypes = {
        javascript = true,
        javascriptreact = true,
        typescript = true,
        typescriptreact = true,
      }

      local function normalize_filetype(ft)
        if js_filetypes[ft] then
          return "javascript"
        end
        return ft
      end

      local normalized_current_ft = normalize_filetype(current_filetype)

      -- Get all loaded buffers and filter diagnostics from them
      local loaded_buffers = vim.api.nvim_list_bufs()
      for _, bufnr in ipairs(loaded_buffers) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          local diag_filetype = vim.bo[bufnr].filetype
          local normalized_diag_ft = normalize_filetype(diag_filetype)

          if normalized_diag_ft == normalized_current_ft then
            local buffer_diagnostics = vim.diagnostic.get(bufnr)
            for _, diag in ipairs(buffer_diagnostics) do
              local severity_str = severity_map[diag.severity] or "Unknown"
              if severity_str ~= "Unknown" then
                severity_counts[diag.severity] = severity_counts[diag.severity] + 1
                local file_path = vim.api.nvim_buf_get_name(bufnr)

                -- Convert to relative path from project root
                local relative_path = vim.fn.fnamemodify(file_path, ":.")
                if vim.startswith(relative_path, "/") then
                  relative_path = file_path
                end

                table.insert(
                  formatted_diagnostics_list,
                  string.format(
                    "%s:%d:%d: %s: [%s] %s",
                    relative_path,
                    diag.lnum + 1,
                    diag.col + 1,
                    diag.source or "Unknown",
                    severity_str,
                    diag.message
                  )
                )
              end
            end
          end
        end
      end

      local final_output = table.concat(formatted_diagnostics_list, "\n")
      vim.fn.setreg("+", final_output)
      if #formatted_diagnostics_list == 0 then
        vim.notify("No diagnostics to copy", vim.log.levels.INFO, { title = "Copy Diagnostics" })
      else
        local ret = ""
        local severities_to_iterate = {
          vim.diagnostic.severity.ERROR,
          vim.diagnostic.severity.WARN,
          vim.diagnostic.severity.INFO,
          vim.diagnostic.severity.HINT,
        }
        for _, severity in ipairs(severities_to_iterate) do
          local count = severity_counts[severity]
          if count > 0 then
            ret = ret
              .. string.format(
                "%s  %d %s\n",
                severity_icons[severity],
                count,
                severity_name[severity]
              )
          end
        end
        if #ret > 0 then
          -- remove last \n
          ret = ret:sub(1, -2)
        end
        vim.notify(ret, vim.log.levels.INFO, { title = "Copy Diagnostics" })
      end
    end, { desc = "Copy diagnostics to clipboard", nowait = true })
  end

  register_diagnostic_yank("yx", {
    vim.diagnostic.severity.ERROR,
    vim.diagnostic.severity.WARN,
    vim.diagnostic.severity.INFO,
    vim.diagnostic.severity.HINT,
  })
  register_diagnostic_yank("yw", {
    vim.diagnostic.severity.ERROR,
    vim.diagnostic.severity.WARN,
    -- vim.diagnostic.severity.INFO,
    -- vim.diagnostic.severity.HINT,
  })
end

local function map_tab_move()
  vim.keymap.set("n", "[<tab>", function()
    local tab_count = vim.fn.tabpagenr("$")
    if tab_count > 1 then
      vim.cmd("tabprevious")
    end
  end, { desc = "Move to previous tab" })

  vim.keymap.set("n", "]<tab>", function()
    local tab_count = vim.fn.tabpagenr("$")
    if tab_count > 1 then
      vim.cmd("tabnext")
    end
  end, { desc = "Move to next tab" })
end

local function map_ufo()
  vim.keymap.set("n", "zR", require("ufo").openAllFolds)
  vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
end

local function map_tab()
  vim.keymap.set({ "i" }, "<tab>", function()
    local sug = require("copilot.suggestion")
    local length = vim.snippet._session ~= nil and #vim.snippet._session.tabstops or nil
    if length ~= nil and length >= 2 and vim.snippet.active({ direction = 1 }) then
      vim.snippet.jump(1)
    elseif sug.is_visible() then
      vim.snippet.stop()
      sug.accept()
    else
      vim.snippet.stop()
      return "<tab>"
    end
  end, { expr = true, desc = "Toggle tab close or new" })
end

local function map_undo_redo()
  vim.keymap.set("n", "u", function()
    local view = vim.fn.winsaveview()
    vim.cmd("undo")
    vim.fn.winrestview(view)
  end, { desc = "Undo without scrolling", silent = true })

  vim.keymap.set("n", "<C-r>", function()
    local view = vim.fn.winsaveview()
    vim.cmd("redo")
    vim.fn.winrestview(view)
  end, { desc = "Redo without scrolling", silent = true })
end

local function map_get_meta()
  vim.keymap.set("n", "<leader>Mf", function()
    local filename = vim.api.nvim_buf_get_name(0)
    vim.notify("filename: " .. filename)
  end)
  vim.keymap.set("n", "<leader>Mt", function()
    local filetype = vim.bo.filetype
    vim.notify("filetype: " .. filetype)
  end)
end

-- if not vim.g.vscode then
map_scroll()
map_hover_scroll()
-- end

reset_keymaps()
map_template_string()
map_react_prop_bracket()
map_delete_buffer()
configure_lsp()
map_docs_hover()
map_shift_cr()
map_comments()
manipulate_yank_paste_register_behavior()
customizeExitInsertMode()
configure_git_diff()
map_esc()
-- map_close_tap_or_buffer()
map_rename()
map_delete_file()
map_enter()
map_recording()
map_split()
map_smart_splits()
map_select_all()
map_git_actions()
map_yank()
map_tab_move()
map_ufo()
map_tab()
map_undo_redo()
map_get_meta()
