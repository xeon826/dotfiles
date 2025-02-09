
return {{
  'nvim-pack/nvim-spectre',
  requires = 'nvim-lua/plenary.nvim', -- if you're using icons
  config = function()
    require('spectre').setup({
        default = {
            replace = {
                cmd = "sed"
          }
        }
    })
  end,
  event = 'VimEnter' -- Ensures it starts after Neovim finishes loading
}}
