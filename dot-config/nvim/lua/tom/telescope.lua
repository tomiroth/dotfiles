local M = {}
-- Custom function to find directories
M.find_directories = function(opts)
    print "testin"
  opts = opts or {}
  require('telescope.builtin').find_files(vim.tbl_extend('force', opts, {
    prompt_title = "Search Directories",
    find_command = {'fd', '--type', 'd'},
  }))
end

return M

