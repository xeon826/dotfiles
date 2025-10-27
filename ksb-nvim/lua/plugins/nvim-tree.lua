--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- File: plugins/tree.lua
-- Description: nvim-tree config
-- Author: Kien Nguyen-Tuan <kiennt2609@gmail.com>
-- disable netrw at the very start of your init.lua (strongly advised)
return {{
    -- File explore
    -- nvim-tree.lua - A file explorer tree for neovim written in lua
  enabled=true,
    "nvim-tree/nvim-tree.lua",
    lazy = true,
		keys = {
			{ mode="n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle tree" } },
			{ mode="n", "<leader>nr", ":NvimTreeRefresh<CR>", { desc = "Refresh tree" } },
			{ mode="n", "<leader>E", ":NvimTreeFindFile<CR>", { desc = "Search for a file in tree" } },
			{ mode="n", "<leader>nf", ":NvimTreeFocus<CR>", { desc = "Focus tree" } },
		},
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    opts = {
        filters = {
            dotfiles = false
        },
        disable_netrw = true,
        hijack_netrw = true,
        hijack_cursor = true,
        hijack_unnamed_buffer_when_opening = false,
        sync_root_with_cwd = true,
        update_focused_file = {
            enable = true,
            update_root = false
        },
        view = {
            adaptive_size = false,
            side = "left",
            width = 30,
            preserve_window_proportions = true
        },
        git = {
            enable = false,
            ignore = true
        },
        filesystem_watchers = {
            enable = true
        },
        actions = {
            open_file = {
                resize_window = true
            }
        },
        renderer = {
            root_folder_label = false,
            highlight_git = false,
            highlight_opened_files = "none",

            indent_markers = {
                enable = false
            },

            icons = {
                show = {
                    file = true,
                    folder = true,
                    folder_arrow = true,
                    git = false
                },

                glyphs = {
                    default = "󰈚",
                    symlink = "",
                    folder = {
                        default = "",
                        empty = "",
                        empty_open = "",
                        open = "",
                        symlink = "",
                        symlink_open = "",
                        arrow_open = "",
                        arrow_closed = ""
                    },
                    git = {
                        unstaged = "✗",
                        staged = "✓",
                        unmerged = "",
                        renamed = "➜",
                        untracked = "★",
                        deleted = "",
                        ignored = "◌"
                    }
                }
            }
        }
    },
    config = function(_, opts)
        opts.on_attach = function(bufnr)
            local api = require("nvim-tree.api")
            local function opts_fn(desc)
                return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
            end
    
            -- Default mappings (without '-')
            vim.keymap.set('n', '<CR>', api.node.open.edit, opts_fn('Open'))
            vim.keymap.set('n', 'o', api.node.open.edit, opts_fn('Open'))
            vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts_fn('Open'))
            vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts_fn('CD'))
            vim.keymap.set('n', '<C-]>', api.tree.change_root_to_node, opts_fn('CD'))
            vim.keymap.set('n', '<C-b>', api.tree.change_root_to_parent, opts_fn('Up directory'))
            vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts_fn('Open: Vertical Split'))
            vim.keymap.set('n', '<C-x>', api.node.open.horizontal, opts_fn('Open: Horizontal Split'))
            vim.keymap.set('n', '<C-t>', api.node.open.tab, opts_fn('Open: New Tab'))
            vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts_fn('Info'))
            vim.keymap.set('n', 'R', api.tree.reload, opts_fn('Refresh'))
            vim.keymap.set('n', 'a', api.fs.create, opts_fn('Create'))
            vim.keymap.set('n', 'd', api.fs.remove, opts_fn('Delete'))
            vim.keymap.set('n', 'r', api.fs.rename, opts_fn('Rename'))
            vim.keymap.set('n', 'x', api.fs.cut, opts_fn('Cut'))
            vim.keymap.set('n', 'c', api.fs.copy.node, opts_fn('Copy'))
            vim.keymap.set('n', 'p', api.fs.paste, opts_fn('Paste'))
            vim.keymap.set('n', 'y', api.fs.copy.filename, opts_fn('Copy Name'))
            vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts_fn('Copy Relative Path'))
            vim.keymap.set('n', 'g?', api.tree.toggle_help, opts_fn('Help'))
            vim.keymap.set('n', 'q', api.tree.close, opts_fn('Close'))
            -- '-' (dir_up) intentionally not mapped
        end
        require("nvim-tree").setup(opts)
    end
}}


