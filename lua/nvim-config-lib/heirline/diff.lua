local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local M = {}

M.block = {
	condition = conditions.is_git_repo,
	init = function(self)
		---@diagnostic disable-next-line: undefined-field
		self.status_dict = vim.b.gitsigns_status_dict
		self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
	end,
}

M.added = {
	provider = function(self)
		local count = self.status_dict.added or 0
		return count > 0 and ("+" .. count)
	end,
}

M.removed = {
	provider = function(self)
		local count = self.status_dict.removed or 0
		return count > 0 and ("-" .. count)
	end,
}

M.changed = {
	provider = function(self)
		local count = self.status_dict.changed or 0
		return count > 0 and ("~" .. count)
	end,
}

M.block = utils.insert(
	M.block,
	{
		condition = function(self)
			return self.has_changes and (self.status_dict.added or self.status_dict.removed or self.status_dict.changed)
		end,
		provider = "(",
	},
	M.added,
	M.removed,
	M.changed,
	{
		condition = function(self)
			return self.has_changes and (self.status_dict.added or self.status_dict.removed or self.status_dict.changed)
		end,
		provider = ")",
	}
)

return M
