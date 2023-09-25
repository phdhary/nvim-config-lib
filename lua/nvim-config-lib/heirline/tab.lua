local utils = require("heirline.utils")

local M = {}

M.page = {
	provider = function(self)
		return "%" .. self.tabpage .. "T " .. self.tabnr .. " %T"
	end,
	hl = function(self)
		return self.is_active and "TabLineSel" or "TabLine"
	end,
}

M.block = {
	condition = function()
		return #vim.api.nvim_list_tabpages() >= 2
	end,
	utils.make_tablist(M.page),
}

return M
