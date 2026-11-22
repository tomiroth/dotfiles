local M = {}

-- vim.pack registers/install these at startup, but `load = function() end`
-- keeps them off 'runtimepath' until first use. After startup, :packadd
-- sources the plugin's plugin/ scripts as usual.
function M.load_plugin(name)
  vim.cmd.packadd({ vim.fn.escape(name, ' '), magic = { file = false } })
end

return M
