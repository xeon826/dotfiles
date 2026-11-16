-- Decade workspace allocation, mode "triple" — written to hypr-custom/decades.lua
-- by switch-monitors.sh. Left DP-2: 1-10 · Center DP-3: 11-20 · Portrait DP-1: 21-30.

local decades = {
	{ monitor = "DP-2", from = 1 },
	{ monitor = "DP-3", from = 11 },
	{ monitor = "DP-1", from = 21 },
}

for _, d in ipairs(decades) do
	for i = 0, 9 do
		hl.workspace_rule({ workspace = tostring(d.from + i), monitor = d.monitor, persistent = true })
	end
end
