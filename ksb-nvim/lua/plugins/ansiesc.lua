return {
	"powerman/vim-plugin-AnsiEsc",
	lazy = true,
	-- Load when AnsiEsc command is used
	keys = {
		{ mode = "n", "<leader>ae", ":AnsiEsc<CR>", { desc = "Escape ANSI sequences" } },
	},
	cmd = "AnsiEsc",
	config = function() end,
}
