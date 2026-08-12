return {
  {
    "rktjmp/lush.nvim",
    { dir = vim.fn.stdpath("config") .. "/theme-mj", lazy = true },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "theme-mj",
    },
  },
}
