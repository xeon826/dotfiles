local constants = {
	LLM_ROLE = "llm",
	USER_ROLE = "user",
	SYSTEM_ROLE = "system",
}
return {
	"olimorris/codecompanion.nvim",
  enabled=true,
  lazy=true,
	opts = {
		opts = {
			log_level = "DEBUG",
		},
		-- adapters = {
		-- 	acp = {
		-- 		claude_code = function()
		-- 			return require("codecompanion.adapters").extend("claude_code", {})
		-- 		end,
		-- 	},
		-- },
		strategies = {
			chat = {
				roles = {
					user = "dan the man",
				},
        -- adapter="claude_code",
				keymaps = {
					send = {
						modes = {
							i = { "<C-CR>", "<C-s>" },
						},
					},
					completion = {
						inline = {
							keymaps = {
								accept_change = { modes = { n = "ga" } },
								reject_change = { modes = { n = "gr" } },
								always_accept = { modes = { n = "gy" } },
							},
						},
						modes = {
							i = "<C-x>",
						},
					},
				},

				slash_commands = {
					["buffer"] = {
						keymaps = {
							modes = {
								i = "<C-b>",
							},
						},
						opts = {
							provider = "snacks",
						},
					},
					["fetch"] = {
						keymaps = {
							modes = {
								i = "<C-f>",
							},
						},
					},
					["file"] = {
						opts = {
							provider = "snacks",
						},
					},
					["help"] = {
						opts = {
							provider = "snacks",
							max_lines = 1000,
						},
					},
					["image"] = {
						keymaps = {
							modes = {
								i = "<C-i>",
							},
						},
					},
				},
			},
		},
		prompt_library = {
			["Edit<->Test workflow"] = {
				strategy = "workflow",
				description = "Use a workflow to repeatedly edit then test code",
				opts = {
					index = 5,
					is_default = true,
					short_name = "et",
				},
				prompts = {
					{
						{
							name = "Setup Test",
							role = constants.USER_ROLE,
							opts = { auto_submit = false },
							content = function()
								-- Enable YOLO mode!
								vim.g.codecompanion_yolo_mode = true

								return [[### Instructions

Your instructions here

Fix the failing tests, note also that pytz needs to be replaced in this django project.

### Steps to Follow

You are required to write code following the instructions provided above and test the correctness by running the designated test suite. Follow these steps exactly:

1. Use the @{cmd_runner} tool to run the test suite with `<test_cmd>`
2. Update the code in the failing test using the tools in the @{full_stack_dev} group
3. Make updates to that and other files as you see fit in order for the tests to pass.

We'll repeat this cycle until all tests pass. Ensure no deviations from these steps.]]
							end,
						},
					},
					{
						{
							name = "Repeat On Failure",
							role = constants.USER_ROLE,
							opts = { auto_submit = true },
							-- Scope this prompt to the cmd_runner tool
							condition = function()
								return _G.codecompanion_current_tool == "cmd_runner"
							end,
							-- Repeat until the tests pass, as indicated by the testing flag
							-- which the cmd_runner tool sets on the chat buffer
							repeat_until = function(chat)
								return chat.tool_registry.flags.testing == true
							end,
							content = "The tests have failed. Can you edit the buffer and run the test suite again?",
						},
					},
				},
			},
		},
		extensions = {
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					make_vars = true,
					make_slash_commands = true,
					show_result_in_chat = true,
					make_tools = true,
					show_server_tools_in_chat = true,
				},
			},
			history = {
				enabled = true,
				opts = {
					keymap = "gh",
					save_chat_keymap = "sc",
					auto_save = true,
					expiration_days = 0,
					picker = "fzf-lua", --- ("telescope", "snacks", "fzf-lua", or "default")
					chat_filter = nil,
					picker_keymaps = {
						rename = { n = "r", i = "<M-r>" },
						delete = { n = "d", i = "<M-d>" },
						duplicate = { n = "<C-y>", i = "<C-y>" },
					},
					auto_generate_title = true,
					title_generation_opts = {
						adapter = nil,
						model = nil,
						refresh_every_n_prompts = 0,
						max_refreshes = 3,
						format_title = function(original_title)
							return original_title
						end,
					},
					continue_last_chat = false,
					delete_on_clearing_chat = false,
					dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
					enable_logging = false,
					summary = {
						create_summary_keymap = "gcs",
						browse_summaries_keymap = "gbs",
						generation_opts = {
							adapter = nil,
							model = nil,
							context_size = 90000,
							include_references = true,
							include_tool_outputs = true,
							system_prompt = nil,
							format_summary = nil,
						},
					},
					memory = {
						auto_create_memories_on_summary_generation = true,
						vectorcode_exe = "vectorcode",
						tool_opts = {
							default_num = 10,
						},
						notify = true,
						index_on_startup = false,
					},
				},
			},
		},
	},
	keys = {
		{
			"<leader>a",
			"<cmd>CodeCompanionChat Toggle<CR>",
			mode = { "n" },
			desc = "Toggle CodeCompanion Chat",
			noremap = true,
			silent = true,
		},
		{
			"<leader>ca",
			"<cmd>CodeCompanionActions<CR>",
			mode = { "n" },
			desc = "Open CodeCompanionActions",
			noremap = true,
			silent = true,
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"franco-ruggeri/codecompanion-spinner.nvim",
		"ravitemer/codecompanion-history.nvim",
		{
			"ravitemer/mcphub.nvim",
			build = "/usr/bin/npm install -g mcp-hub@latest",
			config = {
				global_env = {
					"GITHUB_PERSONAL_ACCESS_TOKEN",
					"FIRECRAWL_API_KEY",
				},
			},
		},
	},
}
