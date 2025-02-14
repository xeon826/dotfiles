local utils = require("config/utils")
return {
	{
		"akinsho/bufferline.nvim",
		requires = "kyazdani42/nvim-web-devicons", -- if you're using icons
		keys = {
			{ "<C-S-L>", "<cmd>BufferLineMoveNext<CR>", { noremap = true, silent = true, desc = "Move buffer right" } },
			{ "<C-S-H>", "<cmd>BufferLineMovePrev<CR>", { noremap = true, silent = true, desc = "Move buffer left" } },
			{ "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { noremap = true, silent = true, desc = "Previous buffer" } },
			{ "<S-l>", "<cmd>BufferLineCycleNext<CR>", { noremap = true, silent = true, desc = "Next buffer" } },
			{
				"<leader>bcu",
				utils.close_unpinned_buffers,
				{ noremap = true, silent = true, desc = "Close unpinned buffers" },
			},
			{ "<leader>bd", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Delete current buffer" } },
			{
				"<leader>bp",
				"<cmd>BufferLineTogglePin<CR>",
				{ noremap = true, silent = true, desc = "Toggle pin for current buffer" },
			},
			{
				"<leader>bco",
				"<cmd>BufferLineCloseOthers<CR>",
				{ noremap = true, silent = true, desc = "Close all aside from the current buffer" },
			},
		},
		config = function()
			local bufferline = require("bufferline")
			bufferline.setup({
				options = {
					separator_styling = "padded_slope",
				},
			})
		end,
		event = "VimEnter", -- Ensures it starts after Neovim finishes loading
	},
}
