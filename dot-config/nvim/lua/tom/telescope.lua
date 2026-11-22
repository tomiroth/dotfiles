local M = {}

-- Load telescope and apply config on first use.
function M.load()
  require('tom.lazy').load_plugin('telescope.nvim')
  if vim.g.tom_telescope_loaded then
    return
  end
  vim.g.tom_telescope_loaded = true

  local actions = require('telescope.actions')
  require('telescope').setup {
    defaults = {
      mappings = {
        n = {
          ['<c-d>'] = actions.delete_buffer,
        },
        i = {
          ['<C-h>'] = 'which_key',
          ['<c-d>'] = actions.delete_buffer,
        },
      },
    },
  }
  require('telescope').load_extension('luasnip')
end

-- Custom function to find directories
M.find_directories = function(opts)
  M.load()
  opts = opts or {}
  require('telescope.builtin').find_files(vim.tbl_extend('force', opts, {
    prompt_title = "Search Directories",
    find_command = { 'fd', '--type', 'd' },
  }))
end

-- Custom function to grep file contents (via ripgrep) in the current file's directory
M.live_grep_current_dir = function(opts)
  M.load()
  opts = opts or {}
  require('telescope.builtin').live_grep(vim.tbl_extend('force', opts, {
    prompt_title = "Live Grep (Current Dir)",
    cwd = vim.fn.expand("%:p:h"),
  }))
end

return M
