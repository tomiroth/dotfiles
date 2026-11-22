-- templ's highlight/injection queries declare "inherits: go", which only
-- resolves once the go parser+queries are installed alongside templ's.
local installed = require("nvim-treesitter").get_installed()
local missing = vim.iter({ "templ", "go" })
    :filter(function(lang) return not vim.tbl_contains(installed, lang) end)
    :totable()

if #missing == 0 then
  vim.treesitter.start()
else
  require("nvim-treesitter").install(missing):await(function()
    vim.treesitter.start()
  end)
end
