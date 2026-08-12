return {
  "gbprod/yanky.nvim",
  enabled = true,
  recommended = true,
  desc = "Better Yank/Paste",
  event = "LazyFile",
  opts = {
    highlight = {
      timer = 200,
      on_put = true,
      on_yank = true,
    },
  },
}
