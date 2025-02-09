return {{
  'akinsho/bufferline.nvim',
  requires = 'kyazdani42/nvim-web-devicons', -- if you're using icons
  config = function()
    local bufferline = require('bufferline')
    bufferline.setup({
      options = {
        separator_styling = 'padded_slope'
      }
      }
    )
  end,
  event = 'VimEnter' -- Ensures it starts after Neovim finishes loading
}}
