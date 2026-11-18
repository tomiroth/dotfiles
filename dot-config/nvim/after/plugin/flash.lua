local flash = require('flash')

flash.setup({
  modes = {
    char = {
      -- Keep f/F/t/T focused on the current line, like the old Hop setup.
      multi_line = false,
    },
  },
})
