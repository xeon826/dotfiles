-- Custom rules (converted from custom/rules.conf)
hl.window_rule({ match = { fullscreen = true }, border_size = 7, rounding = 0 })

-- Bind Claude terminal to special workspace
hl.workspace_rule({
    workspace = "special:opencode",
    on_created_empty = "kitty --directory ~/git_clones --class kitty-opencode -e zsh -i -c opencode",
    gaps_out = 30,
})
hl.workspace_rule({ workspace = "special:browser", gaps_out = 30 })
