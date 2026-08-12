function table.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
    end
    setmetatable(copy, table.deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end
---@diagnostic disable: assign-type-mismatch
---@type snacks.picker.layout.Config
local vscode_layout_preview = {
  preview = true,
  layout = {
    backdrop = true,
    row = 2,
    width = 0.60,
    min_width = 114,
    max_width = 140,
    height = 0.8,
    border = "none",
    box = "vertical",
    {
      win = "input",
      border = "rounded",
      title = "{title} {live} {flags}",
      title_pos = "center",
      focusable = true,
      height = 1,
    },
    { win = "list", border = "rounded", max_height = 15, focusable = true, height = 0.4 },
    {
      wrap = true,
      win = "preview",
      title = "{preview}",
      border = "rounded",
      focusable = true,
      height = 0.6,
    },
  },
}
---@diagnostic disable: assign-type-mismatch
---@type snacks.picker.layout.Config
local vscode_layout_without_preview = {
  preview = false,
  layout = {
    backdrop = true,
    row = 2,
    width = 0.5,
    min_width = 100,
    max_width = 140,
    height = 0.7,
    max_height = 35,
    border = "none",
    box = "vertical",
    {
      win = "input",
      height = 1,
      border = "rounded",
      title = "{title} {live} {flags}",
      title_pos = "center",
      focusable = true,
    },
    { win = "list", border = "rounded", focusable = true },
  },
}

local common_exclude = { ".git", "~", ".idea", ".DS_Store" }

return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  ---@module "snacks.nvim"
  ---@type snacks.Config
  opts = {
    ---@type table<string, snacks.win.Config>
    styles = {
      -- input = {
      --   title_pos = "left",
      --   height = 1,
      --   width = 60,
      -- },
      notification = {
        border = "solid",
        wo = {
          wrap = true,
        },
      },
      notification_history = {
        title_pos = "left",
        wo = {
          wrap = true,
        },
      },
      lazygit = { wo = {} },
    },
    terminal = {
      shell = "zsh",
      win = {},
    },
    notifier = {
      enabled = true,
      timeout = 1800,
      width = { min = 35, max = 70 },
      height = { min = 1, max = 50 },
      sort = { "added", "level" },
      ---@type snacks.notifier.style
      style = "minimal",
    },
    statuscolumn = {
      left = { "mark", "fold" }, -- priority of signs on the left (high to low)
      right = { "git" }, -- priority of signs on the right (high to low)
      folds = {
        open = true, -- show open fold icons
        git_hl = false, -- use Git Signs hl for fold icons
      },
      git = {
        -- patterns to match Git signs
        patterns = { "GitSign", "MiniDiffSign" },
      },
      refresh = 50, -- refresh at most every 50ms
    },
    scroll = {
      enabled = false,
      animate = { duration = { step = 32, total = 160 }, easing = "linear" },
      animate_repeat = { delay = 50, duration = { step = 20, total = 30 }, easing = "linear" },
      -- filter = function (buf)
      --
      -- end
    },
    indent = { enabled = true, priority = 1, only_current = true, only_scope = true },
    image = {
      enabled = true,
      force = true,
      doc = { enabled = true, inline = true, float = true },
    },
    ---@type snacks.explorer.Config
    explorer = {
      replace_netrw = false,
    },
    ---@type snacks.picker.Config
    picker = {
      hidden = true,
      -- ignored = true,
      sources = {
        notifications = { layout = vscode_layout_preview },
        highlights = { layout = vscode_layout_preview },
        files = {
          ignored = false,
          hidden = true,
          layout = vscode_layout_without_preview,
          exclude = common_exclude,
          win = {
            input = {
              keys = {
                ["<up>"] = { "history_back", mode = { "i", "n" } },
                ["<down>"] = { "history_forward", mode = { "i", "n" } },
                ["<esc>"] = { "close", mode = { "i", "n" } },
              },
            },
          },
        },
        select = {
          win = {
            input = {
              keys = {
                ["<esc>"] = { "close", mode = { "i", "n" } },
              },
            },
          },
          layout = {
            preview = true,
            -- preset = "dropdown",
            layout = {
              backdrop = false,
              -- row = 3,
              -- col = 1,
              width = 0.4,
              min_width = 40,
              height = 0.4,
              min_height = 3,
              box = "vertical",
              border = "rounded",
              title = "{title}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
              { win = "preview", title = "{preview}", height = 0.4, border = "top" },
            },
          },
        },
        grep = {
          exclude = common_exclude,
          hidden = true,
          ignored = false,
          layout = vscode_layout_preview,
          win = {
            input = {
              keys = {
                ["<up>"] = { "history_back", mode = { "i", "n" } },
                ["<down>"] = { "history_forward", mode = { "i", "n" } },
                ["<esc>"] = { "close", mode = { "i", "n" } },
                ["<tab>"] = { "focus_list", mode = { "i", "n" } },
              },
            },
            list = {
              keys = {
                -- ["<esc>"] = { "close", mode = { "i", "n" } },
                ["<tab>"] = { "focus_preview", mode = { "i", "n" } },
              },
            },
            preview = {
              keys = {
                -- ["<esc>"] = { "close", mode = { "i", "n" } },
                ["<tab>"] = { "focus_input", mode = { "i", "n" } },
              },
            },
          },
        },
        explorer = {
          hidden = true,
          exclude = common_exclude,
          ignored = true,
          diagnostics = true,
          follow_file = false,
          git_status_open = false,
          confirm = true,
          auto_confirm = false,
          focus = "list",
          title = " " .. vim.fn.fnamemodify(vim.fs.root(0, { ".git" }) or "", ":t"),
          -- -@type fun(item:snacks.picker.finder.Item, ctx:snacks.picker.finder.ctx):(boolean|snacks.picker.finder.Item|nil)
          -- transform = function(item, ctx)
          --   local is_empty = ctx.filter:is_empty()
          --
          --   if not is_empty then
          --     return true
          --   end
          --
          --   if item.dir and item.parent == nil then
          --     return false
          --   end
          --   local original = table.deepcopy(item)
          --   local cur = original
          --   while cur.parent ~= nil do
          --     if cur.parent.parent == nil then
          --       cur.parent = nil
          --       break
          --     end
          --     cur = cur.parent
          --   end
          --   return original
          -- end,
          layout = {
            layout = {
              backdrop = false,
              width = 42,
              min_width = 42,
              height = 0,
              enter = false,
              position = "left",
              border = "none",
              box = "vertical",
              -- {
              --   win = "input",
              --   height = 1,
              --   border = "rounded",
              --   title = "{title} {live} {flags}",
              --   title_pos = "left",
              -- },
              { win = "list", border = "none" },
              { win = "preview", title = "{preview}", height = 0.4, border = "top" },
            },
          },
          win = {
            list = {
              keys = {
                ["a"] = false,
                ["n"] = "explorer_add",
                ["<F6>"] = "explorer_rename",
                ["<M-h>"] = function()
                  require("smart-splits").resize_left(5)
                end,
                ["<M-j>"] = function()
                  require("smart-splits").resize_down(3)
                end,
                ["<M-k>"] = function()
                  require("smart-splits").resize_up(3)
                end,
                ["<M-l>"] = function()
                  require("smart-splits").resize_right(5)
                end,
                ["<C-h>"] = function()
                  require("smart-splits").move_cursor_left({ at_edge = "stop" })
                end,
                ["<C-j>"] = function()
                  require("smart-splits").move_cursor_down({ at_edge = "stop" })
                end,
                ["<C-k>"] = function()
                  require("smart-splits").move_cursor_up({ at_edge = "stop" })
                end,
                ["<C-l>"] = function()
                  local wins = vim.api.nvim_list_wins()
                  local cur_win = vim.api.nvim_get_current_win()
                  -- for i, win in ipairs(wins) do
                  --   vim.notify(i .. ", " .. win)
                  -- end
                  -- vim.notify("cur win " .. cur_win)
                  local buf_id = vim.api.nvim_win_get_buf(cur_win)
                  local buf_name = vim.api.nvim_buf_get_name(buf_id)

                  local pickers = Snacks.picker.get({ source = "explorer" })
                  local is_explorer_visible = #pickers >= 1

                  if buf_name == "" and is_explorer_visible then
                    --    for _, win in ipairs(wins) do
                    --    local position = vim.api.nvim_win_get_position(win)
                    --    vim.notify("win: " .. win ..position)
                    ---   end
                    vim.api.nvim_set_current_win(wins[1])
                  else
                    require("smart-splits").move_cursor_right({ at_edge = "stop" })
                  end
                  -- vim.notify("buf_name " .. buf_name)
                end,
              },
            },
          },
          icons = {
            files = {
              enabled = true, -- show file icons
              dir = "󰉋 ",
              dir_open = "󰝰 ",
              file = "󰈔 ",
            },
            keymaps = {
              nowait = "󰓅 ",
            },
            tree = {
              vertical = "│ ",
              middle = "├╴",
              last = "└╴",
            },
            undo = {
              saved = " ",
            },
            ui = {
              live = "󰐰 ",
              hidden = "h",
              ignored = "i",
              follow = "f",
              selected = "● ",
              unselected = "○ ",
              -- selected = " ",
            },
            git = {
              enabled = true, -- show git icons
              commit = "󰜘 ", -- used by git log
              staged = "●", -- staged changes. always overrides the type icons
              unmerged = " ",
              renamed = "",
              untracked = "?",
              -- ignored = " ",
              -- added = "",
              -- deleted = "",
              -- modified = "○",
              ignored = "",
              added = "",
              deleted = "",
              modified = "",
            },
            diagnostics = {
              Error = " ",
              Warn = " ",
              Hint = " ",
              Info = " ",
            },
            lsp = {
              unavailable = "",
              enabled = " ",
              disabled = " ",
              attached = "󰖩 ",
            },
            kinds = {
              Array = " ",
              Boolean = "󰨙 ",
              Class = " ",
              Color = " ",
              Control = " ",
              Collapsed = " ",
              Constant = "󰏿 ",
              Constructor = " ",
              Copilot = " ",
              Enum = " ",
              EnumMember = " ",
              Event = " ",
              Field = " ",
              File = " ",
              Folder = " ",
              Function = "󰊕 ",
              Interface = " ",
              Key = " ",
              Keyword = " ",
              Method = "󰊕 ",
              Module = " ",
              Namespace = "󰦮 ",
              Null = " ",
              Number = "󰎠 ",
              Object = " ",
              Operator = " ",
              Package = " ",
              Property = " ",
              Reference = " ",
              Snippet = "󱄽 ",
              String = " ",
              Struct = "󰆼 ",
              Text = " ",
              TypeParameter = " ",
              Unit = " ",
              Unknown = " ",
              Value = " ",
              Variable = "󰀫 ",
            },
          },
        },
      },
      sort = {},
      matcher = {
        fuzzy = true,
        smartcase = true,
        ignorecase = true,
        filename_bonus = true,
        history_bonus = false,
        frecency = true,
        cwd_bonus = false,
      },
      formatters = {
        file = {
          filename_first = true,
          truncate = 80,
          icon_width = 3,
        },
        severity = {
          icons = true,
          level = false,
          pos = "right",
        },
      },
      previewers = {
        file = {
          max_size = 1024 * 1024 * 5,
        },
      },
    },
    dashboard = {
      preset = {
        pick = function(cmd, opts)
          return LazyVim.pick(cmd, opts)()
        end,
        header = [[
           *  ' '  *  
              * . .   
              *   ' * 
                  '   
                *   * 
/\ "-./  \     /\ \
\ \ \-./\ \   _\_\ \
  \ \_\ \ \_\ /\_____\
    \/_/  \/_/ \/_____/ ]],
        -- stylua: ignore
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          -- { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
  },
  keys = {
    {
      "<leader>/",
      function()
        local root = vim.fs.root(0, { ".git" })
        Snacks.picker.grep({
          ignored = false,
          title = "Search Text",
          cwd = root,
          enter = true,
        })
      end,
      desc = "Search Text",
    },
    {
      "<leader><space>",
      function()
        local root = vim.fs.root(0, { ".git" })
        Snacks.picker.files({
          ignored = false,
          title = "Files",
          cwd = root,
          enter = true,
        })
      end,
      desc = "Find Files",
    },
    {
      "<leader>e",
      function()
        local root = vim.fs.root(0, { ".git" })
        Snacks.picker.explorer({
          enter = false,
          cwd = root,
          ignored = true,
          hidden = true,
          follow_file = false,
        })
      end,
      desc = "Open Explorer",
    },
    {
      "<F1>",
      function()
        local picker = Snacks.explorer.reveal({})
        require("snacks.picker.actions").focus_list(picker)
      end,
      desc = "Reveal in explorer",
    },
  },
}
