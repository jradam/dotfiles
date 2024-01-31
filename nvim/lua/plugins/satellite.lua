return {
  "lewis6991/satellite.nvim",
  config = function()
    vim.api.nvim_create_autocmd("FocusGained", {
      pattern = "*",
      command = ":SatelliteRefresh", -- To stop crashing when returning focus
    })
    require("satellite").setup()
  end,
}
