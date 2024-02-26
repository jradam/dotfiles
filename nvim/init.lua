-- Bootstrap lazy plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Terminal intercepts the F13 on_activate from KeyChef's `;` press and sends `¦` instead
-- (F keys not available in Neovim)
-- We disable `¦` here so it is never actually typed, and so `¦` acts like a modifier key
-- This means we can use both our new keyboard layer and our leader key with one key
vim.keymap.set({ "n", "i", "v", "t" }, "¦", "<Nop>", { desc = "Disable ¦" })

-- Leader keymap
vim.g.mapleader = "¦"
vim.g.maplocalleader = " "

-- Load plugins
require("lazy").setup({
  { import = "plugins" },
  { import = "plugins.cmp" },
  { import = "plugins.lsp" },
}, {
  install = { colorscheme = { "dracula" } },
  change_detection = { notify = false },
})

-- Setup
require("helpers")
require("keymaps")
require("settings")
require("utilities")

-- TODO: go through each plugin and make Lazy as possible
-- TODO: remap keyboard keys
-- TODO: bigfile.nvim
-- TODO: separate envs for vite, next, etc
-- TODO: silence "tag not found" error
