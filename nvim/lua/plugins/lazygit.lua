local utils = require("config/utils")
-- nvim v0.8.0
return {
	"kdheepak/lazygit.nvim",
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
	keys = {
		{ mode = "n", "<leader>gch", "<leader>gch", utils.my_git_bcommits, desc = "Find Files" },
		{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
	},
	-- optional for floating window border decoration
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
}
