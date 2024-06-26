local M = {}
local h = require("helpers")

-- Run tsc and eslint and put all results in one quickfix list
-- TODO: Make this own plugin
function M.ts_quickfix()
  -- Clear quickfix list
  vim.fn.setqflist({})

  vim.api.nvim_command("echo 'Running tsc...'")
  vim.api.nvim_command("compiler tsc | setlocal makeprg=npx\\ tsc")
  vim.api.nvim_command("silent make")

  -- Get ts_errors back from quickfix
  local ts_errors = vim.fn.getqflist()

  vim.api.nvim_command("echo 'Running eslint...'")
  vim.api.nvim_command(
    "compiler eslint | setlocal makeprg=yarn\\ lint\\ --format\\ compact"
  )
  vim.api.nvim_command("silent make")

  -- Get eslint errors and append them to ts errors
  local eslint_errors = vim.fn.getqflist()
  for _, err in ipairs(eslint_errors) do
    table.insert(ts_errors, err)
  end

  -- Send the now combined list to quickfix
  if #ts_errors > 0 then
    vim.fn.setqflist(ts_errors)
  else
    vim.api.nvim_command("echo 'No errors found.'")
  end
end

-- Easypick custom diff preview
function M.diff_preview(opts)
  local previewers = require("telescope.previewers")
  local putils = require("telescope.previewers.utils")

  return previewers.new_buffer_previewer({
    title = "Diff preview",
    get_buffer_by_name = function(_, entry) return entry.value end,
    define_preview = function(self, entry, _)
      local file_name = entry.value
      local diff_command

      if not opts then
        diff_command = { "git", "--no-pager", "diff", "--", file_name }
      else
        diff_command = {
          "git",
          "--no-pager",
          "diff",
          opts.base_branch,
          "--",
          file_name,
        }
      end

      putils.job_maker(diff_command, self.state.bufnr, {
        value = file_name,
        bufname = self.state.bufname,
        winid = self.state.winid,
      })
      putils.regex_highlighter(self.state.bufnr, "diff")
    end,
  })
end

-- TODO: add a `yarn` in the `env/` dir to the bash install script
-- NOTE: very useful https://github.com/3rd/linter
-- https://github.com/3rd/config/blob/master/home/dotfiles/nvim/lua/modules/language-support/lsp.lua
-- TODO: tidy/simplify if possible eslint file

function M.eslint_setup(client)
  local sets = client.config.settings
  local util = require("lspconfig").util

  if sets.options == nil then sets.options = {} end

  local local_eslint = util.root_pattern(".eslintrc*")(vim.fn.getcwd())

  if local_eslint then
    sets.useEslintrc = true
    sets.options.resolvePluginsRelativeTo = local_eslint
  else
    -- FIX: Disabled custom env for now
    -- sets.useEslintrc = false
    -- sets.options.overrideConfigFile = vim.fn.stdpath("config")
    --   .. "/env/.eslintrc.json"
    -- sets.options.resolvePluginsRelativeTo = vim.fn.stdpath("config")
    --   .. "/env/node_modules"
    -- sets.nodePath = vim.fn.stdpath("config") .. "/env/node_modules"
  end
end

-- Nvim-tree helpers
local api = require("nvim-tree.api")
local toggle = 0

-- Nvim-tree multifunction for expanding folders and opening files
function M.multi(node)
  if node.type == nil then
    if toggle == 0 then
      api.tree.expand_all()
      toggle = 1
    else
      api.tree.collapse_all()
      toggle = 0
    end
  else
    api.node.open.edit()
  end
end

-- Nvim-tree replace the open buffer with the one we are opening
function M.open_in_same()
  local node = api.tree.get_node_under_cursor()
  if node and node.type == "file" then
    local status = pcall(function() api.tree.close() end)

    if status then
      local current_buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_delete(current_buf, { force = false })
      vim.api.nvim_command("edit " .. node.absolute_path)
    else
      -- If tree close fails, it's probably the last open window, so nothing to delete
      vim.api.nvim_command("edit " .. node.absolute_path)
    end
  end
end

-- Nvim-tree do not close the tree if it is the last thing open
function M.close_unless_last()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      api.tree.close()
      break
    end
  end
end

-- Nvim-tree if we try to delete an open buffer, close it first to avoid an error
function M.safe_delete()
  local file_to_delete = api.tree.get_node_under_cursor()

  if file_to_delete and file_to_delete.type == "file" then
    local open_buffers = vim.api.nvim_list_bufs()
    local buffer_to_close = nil
    local listed_buffer_count = 0

    for _, buf in ipairs(open_buffers) do
      if vim.bo[buf].buflisted then
        listed_buffer_count = listed_buffer_count + 1
      end

      if vim.api.nvim_buf_get_name(buf) == file_to_delete.absolute_path then
        buffer_to_close = buf
      end
    end

    if buffer_to_close then
      -- If trying to delete last open buffer, open empty new one first
      if listed_buffer_count == 1 and vim.bo[buffer_to_close].buflisted then
        h.close_floats()
        vim.api.nvim_command("enew")
      end

      vim.api.nvim_buf_delete(buffer_to_close, { force = true })
    end

    local success, err = pcall(api.fs.remove, file_to_delete)
    if not success then
      vim.notify("Error deleting file: " .. err, vim.log.levels.ERROR)
    end
  else
    -- Use default method if directory
    api.fs.remove()
  end
end

-- Nvim-tree resize to full height of window
function M.resize_tree()
  local tree_window = require("nvim-tree.view").get_winnr()

  if tree_window then
    local height = vim.api.nvim_get_option_value("lines", {})
    vim.api.nvim_win_set_height(tree_window, height - 3)
  end
end

-- Telescope function to replace files on `<CR>`, or run default action when not opening files
function M.on_enter(telescope)
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")

  -- If there is nothing to select, return
  if not state.get_selected_entry() then return end

  local filepath = state.get_selected_entry().value

  -- If filepath is a string
  if type(filepath) == "string" then
    -- Split the filepath into path, line, and possibly column
    local parts = h.split(filepath, ":")
    local file_path = parts[1]
    local line = parts[2]
    local col = parts[3] or 0

    -- Check if file_path is a valid path and not already open
    if h.is_file_path(file_path) and not h.is_file_open(file_path) then
      -- Close floats to avoid files being opened in small windows
      h.close_floats()
      actions.close(telescope)

      -- Save the current buffer to close
      local existing_buf = vim.api.nvim_get_current_buf()

      -- Open new file and go to line and column
      vim.api.nvim_command("edit " .. vim.fn.fnameescape(file_path))

      if line and col then
        vim.api.nvim_command("normal! " .. line .. "G" .. col .. "|")
      end

      -- Close that old current buffer afterwards
      if h.buf_exists(existing_buf) then
        vim.api.nvim_buf_delete(existing_buf, { force = false })
      end

      -- Exit if handled
      return
    end
  end

  -- Default action if conditions not met
  actions.select_default(telescope)
end

return M
