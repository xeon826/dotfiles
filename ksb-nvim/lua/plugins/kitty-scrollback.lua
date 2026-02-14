return {
	{
		"mikesmithgh/kitty-scrollback.nvim",
		enabled = true,
		lazy = true,
		cmd = {
			"KittyScrollbackGenerateKittens",
			"KittyScrollbackCheckHealth",
			"KittyScrollbackGenerateCommandLineEditing",
		},
		event = { "User KittyScrollbackLaunch" },
		-- version = '*', -- latest stable version, may have breaking changes if major version changed
		-- version = '^6.0.0', -- pin major version, include fixes and features that do not have breaking changes
		config = function()
			require("kitty-scrollback").setup({
				-- Global configuration to prevent exit after yanking
				{
					callbacks = {
						after_launch = function()
							vim.o.wrap = false
						end,
					},
					-- Disable yank register behavior that might trigger exit
					paste_window = {
						yank_register_enabled = false,
					},
					-- Disable keymaps that might cause cursor reset or modal behavior
					keymaps_enabled = false,
					-- Prevent any automatic behavior after operations
					restore_options = false,
				},
			})
		end,
	},
}
