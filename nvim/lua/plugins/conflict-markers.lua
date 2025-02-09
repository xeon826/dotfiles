return {
	{
		"akinsho/git-conflict.nvim",
		version = "*",
		config = function(_, opts)
			require("git-conflict").setup()
		end,
	},
}
