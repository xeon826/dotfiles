--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- File: config/init.lua
-- Description: Main configurations
-- Author: Kien Nguyen-Tuan <kiennt2609@gmail.com>
-- Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system(
        {"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", -- latest stable release
         lazypath})
end
vim.opt.rtp:prepend(lazypath)

-- vim.g.python3_host_prog = '/home/dan/.virtualenvs/neovim/bin/python3'
vim.g.python3_host_prog = 'python3'
-- vim.g.terminal_emulator = 'kitty'
-- vim.api.nvim_set_var('terminal_emulator', 'kitty')
-- vim.opt.shell = 'kitty'

vim.g.mapleader = " "
vim.g.jukit_mappings_ext_enabled = {"py", "ipynb"}
vim.opt.termguicolors = true -- enable 24-bit RGB colors

vim.api.nvim_set_hl(0, "CurSearch", { fg = "#ffffff", bg = "#2D4F67", bold = true })

-- build spec
local spec = {{
    import = "plugins"
}}

local ok, err = pcall(require, "plugins.custom")
if ok then
    spec = {{
        import = "plugins"
    }, {
        import = "plugins.custom"
    }}
end

require("lazy").setup({
    root = vim.fn.stdpath("data") .. "/lazy", -- directory where plugins will be installed
    spec = spec,
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
    rocks = {
        hererocks = true,  -- recommended if you do not have global installation of Lua 5.1.
    },
    defaults = {
        lazy = false, -- should plugins be lazy-loaded?
        version = nil
        -- version = "*", -- enable this to try installing the latest stable versions of plugins
    },
    install = {
        -- install missing plugins on startup
        missing = true,
        -- try to load one of these colorschemes when starting an installation during startup
        colorscheme = {"oxocarbon.nvim", "rose-pine"}

    },
    checker = {
        -- automatically check for plugin updates
        enabled = true,
        -- get a notification when new updates are found
        -- disable it as it's too annoying
        notify = false,
        -- check for updates every day
        frequency = 86400
    },
    change_detection = {
        -- automatically check for config file changes and reload the ui
        enabled = true,
        -- get a notification when changes are found
        -- disable it as it's too annoying
        notify = false
    },
    performance = {
        cache = {
            enabled = true
        }
    },
    state = vim.fn.stdpath("state") .. "/lazy/state.json" -- state info for checker and other things
})

local modules = {"config.autocmds", "config.options", "config.keymaps", "config.custom"}

for _, mod in ipairs(modules) do
    local ok, err = pcall(require, mod)
    -- config.custom may be empty. It's a optional module
    if not ok and not mod == "config/custom" then
        error(("Error loading %s...\n\n%s"):format(mod, err))
    end
end

-- Disable annoying deprecated message
vim.deprecate = function() end
