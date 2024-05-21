require('neogit').setup {
  -- Configuration options here
  integrations = {
    diffview = true  -- Requires 'sindrets/diffview.nvim'
  },
  kind = "replace"  -- This will make Neogit open in the current buffer
}

