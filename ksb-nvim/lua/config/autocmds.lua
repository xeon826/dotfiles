--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- File: config/autocmds.lua
-- Description: Autocommand functions
-- Author: Kien Nguyen-Tuan <kiennt2609@gmail.com>
-- Define autocommands with Lua APIs
-- See: h:api-autocmd, h:augroup
local augroup = vim.api.nvim_create_augroup -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- Create autocommand

-- General settings

-- Highlight on yank
autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = "1000",
		})
	end,
})

-- Don"t auto commenting new lines
autocmd("BufEnter", {
	pattern = "",
	command = "set fo-=c fo-=r fo-=o",
})

-- Enable text wrapping for all filetypes
autocmd("BufEnter", {
	pattern = "*",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
	end,
})

-- Force text wrapping specifically for kitty-scrollback buffers with adaptive settings
autocmd("FileType", {
	pattern = "ksb*",
	callback = function()
		-- Get terminal width to detect narrow terminals (vertical monitors)
		local columns = vim.o.columns

		-- Enable text wrapping with adaptive settings
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.wrapmargin = 0

		-- For narrow terminals (vertical monitors), adjust text display
		if columns < 100 then
			-- On vertical monitors, ensure proper text wrapping
			vim.opt_local.textwidth = columns - 2  -- Leave small margins
			vim.opt_local.showbreak = "↪ "         -- Visual indicator for wrapped lines
			print("Vertical monitor detected: columns=" .. columns .. ", textwidth=" .. vim.opt_local.textwidth:get())
		else
			-- On horizontal monitors, use default settings
			vim.opt_local.textwidth = 0  -- Disable fixed textwidth
			print("Horizontal monitor detected: columns=" .. columns)
		end
	end,
})

-- Force text wrapping for buffers containing "kitty" in their name with adaptive settings
autocmd("BufEnter", {
	pattern = "*kitty*",
	callback = function()
		-- Get terminal width to detect narrow terminals (vertical monitors)
		local columns = vim.o.columns

		-- Enable text wrapping with adaptive settings
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.wrapmargin = 0

		-- For narrow terminals (vertical monitors), adjust text display
		if columns < 100 then
			-- On vertical monitors, ensure proper text wrapping
			vim.opt_local.textwidth = columns - 2  -- Leave small margins
			vim.opt_local.showbreak = "↪ "         -- Visual indicator for wrapped lines
		end
	end,
})

-- Debug autocmd to check buffer settings for kitty-scrollback
autocmd("BufEnter", {
	pattern = "*",
	callback = function()
		local bufname = vim.api.nvim_buf_get_name(0)
		if string.find(bufname:lower(), "kitty") or string.find(bufname:lower(), "ksb") then
			print("Kitty-scrollback buffer detected: " .. bufname)
			print("Current wrap setting: " .. tostring(vim.opt_local.wrap:get()))
			print("Current linebreak setting: " .. tostring(vim.opt_local.linebreak:get()))
		end
	end,
})

autocmd("Filetype", {
	pattern = {
		"xml",
		"html",
		"xhtml",
		"css",
		"scss",
		"javascript",
		"typescript",
		"typescriptreact",
		"javascriptreact",
		"yaml",
		"lua",
	},
	command = "setlocal shiftwidth=2 tabstop=2",
})

-- Set colorcolumn
autocmd("Filetype", {
	pattern = { "python", "rst", "c", "cpp" },
	command = "set colorcolumn=80",
})

autocmd("Filetype", {
	pattern = { "gitcommit", "markdown", "text" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

autocmd("LspAttach", {
	callback = function()
		vim.diagnostic.config({ virtual_text = true, virtual_lines = false })
	end,
})




