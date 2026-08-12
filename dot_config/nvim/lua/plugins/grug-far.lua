return {
  "MagicDuck/grug-far.nvim",
  opts = {
    debounceMs = 200,
    helpLine = { enabled = false },
    showCompactInputs = true,
    showEngineInfo = false,
    transient = false,
    showInputsTopPadding = true,
    keymaps = {
      applyNext = { n = "<cr>" },
      nextInput = { n = "<tab>" },
      prevInput = { n = "<s-tab>" },
      -- historyOpen = { n = "<localleader>h" },
    },
    engines = {
      ripgrep = {},
    },
    prefills = {
      flags = "--smart-case",
    },
    -- Use floating window
    windowCreationCommand = "tabnew",
    openTargetWindow = {
      preferredLocation = "below",
    },
  },
}
