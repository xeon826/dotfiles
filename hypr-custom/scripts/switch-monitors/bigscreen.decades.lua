-- Decade workspace allocation, mode "bigscreen" — written to hypr-custom/decades.lua
-- by switch-monitors.sh. TV HDMI-A-1: 1-10 (only active monitor).

local decades = {
	{ monitor = "HDMI-A-1", from = 1 },
}

for _, d in ipairs(decades) do
	for i = 0, 9 do
		hl.workspace_rule({ workspace = tostring(d.from + i), monitor = d.monitor, persistent = true })
	end
end
