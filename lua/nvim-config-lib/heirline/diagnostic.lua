local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local lib = require("nvim-config-lib.heirline.lib")
local hl = lib.hl

local M = {}

M.block = {
	init = function(self)
		self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
		self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
		self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
		self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
	end,
	condition = conditions.has_diagnostics,
	static = {
		error_icon = "E:", --   ·
		warn_icon = "W:",
		info_icon = "I:",
		hint_icon = "H:",
	},
	update = { "DiagnosticChanged", "BufEnter" },
	hl = function()
		return vim.tbl_extend("force", hl.adaptive_bg(), hl.bold)
	end,
}

M.error = {
	provider = function(self)
		return self.errors > 0 and (self.error_icon .. self.errors .. " ")
	end,
	hl = { fg = "diag_error" },
}

M.warning = {
	provider = function(self)
		return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
	end,
	hl = { fg = "diag_warn" },
}

M.info = {
	provider = function(self)
		return self.info > 0 and (self.info_icon .. self.info .. " ")
	end,
	hl = { fg = "diag_info" },
}

M.hint = {
	provider = function(self)
		return self.hints > 0 and (self.hint_icon .. self.hints)
	end,
	hl = { fg = "diag_hint" },
}

M.block = utils.insert(M.block, M.error, M.warning, M.info, M.hint)

return M
