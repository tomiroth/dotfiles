-- Load nvim-treesitter (opt pack) so :TSInstall etc. are available
local treesitter_path = vim.fn.stdpath('data') .. '/site/pack/core/opt/nvim-treesitter'
vim.cmd.packadd('nvim-treesitter')
package.path = package.path .. ';' .. treesitter_path .. '/lua/?.lua'
package.path = package.path .. ';' .. treesitter_path .. '/lua/?/init.lua'

-- Enable treesitter highlighting via Neovim's built-in vim.treesitter
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and pcall(vim.treesitter.start, args.buf, lang) then
      -- successfully started, nothing more needed
    end
  end,
})
