local wk = require("which-key")
wk.setup {}
wk.add({
  { "<leader>p", group = "Project" }, -- group
  { "<leader>b", group = "Buffers" }, -- group
  { "<leader>d", group = "Dir" }, -- group
  { "<leader>h", group = "Hop" }, -- group
  { "<leader>v", group = "LSP" }, -- group
  { "<leader>v", group = "Quick Menu" }, -- group
})


