return {
  "sindrets/diffview.nvim",
  opts = {
    -- enhanced_diff_hl = true,
    file_panel = {
      listing_style = "tree",
      win_config = {
        position = "bottom",
        height = 16,
      },
      tree_options = {
        flatten_dirs = false,
      },
    },
    file_history_panel = {
      listing_style = "tree",
      win_config = {
        position = "bottom",
        height = 16,
        -- width = 35,
        win_opts = {},
      },
    },
  },
}
