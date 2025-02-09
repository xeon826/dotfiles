return {{
  'WhoIsSethDaniel/toggle-lsp-diagnostics.nvim',
  config = function()
    require('toggle_lsp_diagnostics').init()
  end,
  event = 'VimEnter' -- Ensures it starts after Neovim finishes loading
}}
