-- Ensure you have a foldcolumn for better visibility
vim.o.foldcolumn = '1'      -- Show fold column
vim.o.foldlevel = 99        -- Start with all folds open
vim.o.foldlevelstart = 99   -- Start with no folds closed
vim.o.foldenable = true     -- Enable folding

-- Use Treesitter as the folding method
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'

-- Load nvim-ufo with settings
require('ufo').setup({
     provider_selector = function(bufnr, filetype, buftype)
        if filetype == 'php' then
            return {'indent'} -- Use Treesitter first, then indent
        end
        return {'treesitter', 'indent'} -- Default fallback for all filetypes
    end
})
