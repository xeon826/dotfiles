return {
  {
    "lervag/vimtex",
    -- tag = "v2.15", -- uncomment to pin to a specific release
    keys = {
      { "<leader>vc", "<cmd>VimtexCompile<cr>", { desc = "Vimtex compile", silent = true } },
      { "<leader>vv", "<cmd>VimtexView<cr>", { desc = "Vimtex view", silent = true } },
      { "<leader>ve", "<cmd>VimtexErrors<cr>", { desc = "Vimtex errors", silent = true } },
    },
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = "zathura"
    end
  }
}
