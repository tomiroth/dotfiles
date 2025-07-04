require("noice").setup({
 messages = {
    view = "mini",
  },
  views = {
    mini = {
      backend = "mini",
      align = "message-left",
      timeout = 5000, -- 5 seconds
      position = {
        row = -1,
        col = 0,
      },
      size = {
        width = "auto",
        height = "auto",
      },
      border = { style = "none" },
      win_options = {
        winblend = 0,
        winhighlight = {
          Normal = "Normal",
          FloatBorder = "FloatBorder",
        },
      },
    },
  },
 routes = {
    {
      filter = {
        event = "msg_showmode",
      },
      view = "mini",  -- or "notify" or even "echo" depending on what works
    },
  },

  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = true, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
})

vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function(args)
    local filename = vim.fn.fnamemodify(args.file, ":~:.")
    require("noice").notify("Saved: " .. filename, "info", { title = "File Saved" })
  end,
})

