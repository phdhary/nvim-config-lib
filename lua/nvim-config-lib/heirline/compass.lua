local conditions = require("heirline.conditions")

local lib = require("nvim-config-lib.heirline.lib")
local ft_to_hide_compass_and_flag = lib.ft_to_hide_compass_and_flag
local Space = lib.Space

local M = {}

M.ruler = { provider = "%(%l/%L%):%c" }

M.scrollBar = {
	static = { sbar = { "🭶", "🭷", "🭸", "🭹", "🭺", "🭻" } },
	provider = function(self)
		local curr_line = vim.api.nvim_win_get_cursor(0)[1]
		local lines = vim.api.nvim_buf_line_count(0)
		local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
		return string.rep(self.sbar[i], 2)
	end,
}

M.block = {
	condition = function()
		if vim.bo.filetype == "neo-tree" then
			return false
		end
		return not conditions.buffer_matches({
			filetype = ft_to_hide_compass_and_flag,
		})
	end,
	flexible = 2,
	{ Space, M.ruler },
	{},
}

return M
