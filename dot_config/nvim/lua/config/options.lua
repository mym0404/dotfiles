-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.ambiwidth = "single"
opt.autowrite = true
opt.swapfile = false
opt.conceallevel = 0
opt.termguicolors = true
opt.list = false
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

opt.iminsert = 0
opt.imsearch = 0

opt.guicursor =
"n-v-c-sm:block-blinkwait1000-blinkon500-blinkoff500,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor"

opt.autoindent = true
opt.smartindent = true
opt.cindent = true
opt.expandtab = true
-- opt.tabstop = 2
-- opt.shiftwidth = 8

opt.imsearch = 0

-- opt.mouse = ""
-- vim.o.mousemodel = "extend"
opt.showmode = false
opt.exrc = true

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"

  -- Fix "waiting for osc52 response from terminal" message
  -- https://github.com/neovim/neovim/issues/28611

  if vim.env.SSH_TTY ~= nil then
    -- Set up clipboard for ssh

    local function my_paste(_)
      return function(_)
        local content = vim.fn.getreg('"')
        return vim.split(content, '\n')
      end
    end

    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      paste = {
        -- No OSC52 paste action since wezterm doesn't support it
        -- Should still paste from nvim
        ['+'] = my_paste('+'),
        ['*'] = my_paste('*'),
      },
    }
  end
end)

opt.breakindent = true
opt.ignorecase = true
opt.smartcase = true

opt.termguicolors = true

vim.g.lazyvim_prettier_needs_config = true
-- vim.g.lazyvim_cmp = "nvim-cmp"
-- vim.g.snacks_animate = false

opt.foldmethod = "manual"
vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep:|,foldclose:]]

opt.laststatus = 3
vim.o.winborder = "rounded"

vim.g.ai_cmp = false
vim.g.vim_json_conceal = 0

vim.g.autoformat = true
vim.g.lazyvim_eslint_auto_format = true
vim.g.lazyvim_prettier_needs_config = true
