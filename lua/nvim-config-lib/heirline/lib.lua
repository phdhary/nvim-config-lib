local conditions = require("heirline.conditions")

local M = {}

M.Align = { provider = "%=" }
M.Space = { provider = " " }
M.CutHere = { provider = "%<" }

M.ft_to_hide_compass_and_flag = {
	"dapui_breakpoints",
	"dapui_scopes",
	"dapui_stacks",
	"dapui_watches",
	"DiffviewFileHistory",
	"DiffviewFiles",
	"neo-tree",
}


M.hl = {
	bold = { bold = true },
	normal_fg = { fg = "black" },
}

function M.hl.adaptive_bg()
	return {
		bg = conditions.is_active() and "gray" or "white",
		force = true,
	}
end

function M.hl.filename(self)
	local hl_table = vim.tbl_extend("force", M.hl.adaptive_bg(), M.hl.normal_fg, M.hl.bold)
	if self.is_modified then
		hl_table.fg = "constant_fg"
	end
	return hl_table
end

return M
