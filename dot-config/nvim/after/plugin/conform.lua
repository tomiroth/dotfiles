require("conform").setup({
  formatters_by_ft = {
    html = { "prettier" },
    css = { "prettier" },
    javascript = { "prettier" },
    templ = { "templ" },
  },
  -- Optional: Format on save
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})

-- Optional: Keymap to format manually
vim.keymap.set({ "n", "v" }, "<leader>mp", function()
  require("conform").format({
    lsp_fallback = true,
    async = false,
    timeout_ms = 500,
  })
end, { desc = "Format file or range" })
