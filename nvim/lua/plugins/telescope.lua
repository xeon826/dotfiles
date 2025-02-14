--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- File: plugins/telescope.lua
-- Description: nvim-telescope config
-- Author: Kien Nguyen-Tuan <kiennt2609@gmail.com>
return {
	{
		-- Telescope
		-- Find, Filter, Preview, Pick. All lua, all the time.
		"nvim-telescope/telescope.nvim",
		keys = {
			{ mode="n", "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find Files" },
			{ mode="n", "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live Grep" },
			{ mode="n", "<leader>fr", function() require("telescope.builtin").resume() end, desc = "Resume" },
			{ mode="n", "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
			{ mode="n", "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help Tags" },
			{ mode="n", "<leader>t", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "Open diagnostics" },
			{ mode="n", "<leader>d", "<cmd>Telescope diagnostics bufnr=0<CR>", desc = "Show buffer diagnostics" },
			{ mode="n", "gr", "<cmd>Telescope lsp_references<CR>", desc = "Show LSP references" },
			{ mode="n", "gc", vim.lsp.buf.declaration, desc = "Go to declaration" },
			{ mode="n", "gd", "<cmd>Telescope lsp_definitions<CR>", desc = "Show LSP definitions" },
			{ mode="n", "gi", "<cmd>Telescope lsp_implementations<CR>", desc = "Show LSP implementations" },
			{ mode="n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", desc = "Show LSP type definitions" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<C-n>"] = actions.cycle_previewers_next,
							["<C-b>"] = actions.cycle_previewers_prev,
						},
					},
				},
			})
			-- To get fzf loaded and working with telescope, you need to call
			-- load_extension, somewhere after setup function:
			require("telescope").load_extension("fzf")
		end,
	},
}
