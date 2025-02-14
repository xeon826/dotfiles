return {
	{
		"nvim-pack/nvim-spectre",
		requires = "nvim-lua/plenary.nvim", -- if you're using icons
		keys = {
			{ mode = "n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', desc = "Toggle Spectre" },
			{ mode = "n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', desc = "Search current word" },
			{ mode = "n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', desc = "Search current file" },
		},
		config = function()
			require("spectre").setup({
				default = {
					replace = {
						cmd = "sed",
					},
				},
			})
		end,
	},
}
