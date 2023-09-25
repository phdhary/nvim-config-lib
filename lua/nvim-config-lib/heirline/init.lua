local utils = require("heirline.utils")
local lib = require("nvim-config-lib.heirline.lib")

local M = {}

local function setup_colors()
	return {
		string_fg = utils.get_highlight("String").fg,
		constant_fg = utils.get_highlight("Constant").fg,
		special_fg = utils.get_highlight("Special").fg,
		diag_warn = utils.get_highlight("DiagnosticWarn").fg,
		diag_error = utils.get_highlight("DiagnosticError").fg,
		diag_hint = utils.get_highlight("DiagnosticHint").fg,
		diag_info = utils.get_highlight("DiagnosticInfo").fg,
		gray = utils.get_highlight("StatusLine").bg,
		black = utils.get_highlight("StatusLine").fg,
		white = utils.get_highlight("StatusLineNC").bg,
	}
end

lib.options = {
	nerd_fonts = true,
}

M.setup = function(opts)
	if opts then
		lib.options.nerd_fonts = opts.nerd_fonts
	end

	local FileName = require("nvim-config-lib.heirline.filename")
	local Diff = require("nvim-config-lib.heirline.diff")
	local Diagnostic = require("nvim-config-lib.heirline.diagnostic")
	local Compass = require("nvim-config-lib.heirline.compass")
	local Tab = require("nvim-config-lib.heirline.tab")

	require("heirline").setup({
		statusline = {
			lib.Space,
			FileName.block,
			lib.Space,
			utils.insert({ flexible = 1 }, { Diff.block, lib.Space, Diagnostic.block }, { Diagnostic.block }, {}),
			lib.Align,
			Compass.block,
			lib.Space,
		},
		tabline = { lib.Align, Tab.block },
		opts = { colors = setup_colors },
	})

	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			utils.on_colorscheme(setup_colors)
		end,
		group = vim.api.nvim_create_augroup("Heirline", { clear = true }),
	})
end

return M
