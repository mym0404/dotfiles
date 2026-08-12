return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = true,
  opts = {
    enabled = function()
      return false
    end,
  },
}
