return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = function()
    local status, builtin = pcall(require, "telescope.builtin")
    if not status then return end

    return {
      {
	"<leader>f",
	function() builtin.find_files({ initial_mode = "insert" }) end,
	desc = "Find file",
      },
      {
	"<leader>s",
	function() builtin.live_grep({ initial_mode = "insert" }) end,
	desc = "Find string",
      },
      {
	"<leader>t",
	":TodoTelescope<CR>",       
	desc = "Find todo" 
      },
      {
	"<leader>r",
	function() builtin.resume({ initial_mode = "normal" }) end,
	desc = "Resume find",
      },
    }
  end,
  opts = function()
    local actions = require("telescope.actions")

    return {
      defaults = {
	initial_mode = "normal",
	layout_strategy = "vertical",
	layout_config = {
	  height = 100,
	  width = 100,
	  scroll_speed = 9,
	  mirror = true,
	  preview_height = 0.7,
	  -- If window is too small, don't show preview section
	  preview_cutoff = 30,
	},
	file_ignore_patterns = { "node_modules", "yarn.lock" },
      },
    }
  end,
}
