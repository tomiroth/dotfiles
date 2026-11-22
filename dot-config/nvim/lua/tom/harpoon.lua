local M = {}

function M.load()
  require('tom.lazy').load_plugin('harpoon')
  if not vim.g.tom_harpoon_loaded then
    vim.g.tom_harpoon_loaded = true
    require('harpoon'):setup()
  end
  return require('harpoon')
end

return M
