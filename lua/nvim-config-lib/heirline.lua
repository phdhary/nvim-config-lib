local M = {}

M.setup = function()
	local Align = { provider = "%=" }
	local Space = { provider = " " }
	local CutHere = { provider = "%<" }
	local ft_to_hide_compass_and_flag = {
		"dapui_breakpoints",
		"dapui_scopes",
		"dapui_stacks",
		"dapui_watches",
		"DiffviewFileHistory",
		"DiffviewFiles",
		"neo-tree",
	}

	local conditions = require("heirline.conditions")
	local utils = require("heirline.utils")

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

	local hl = {
		bold = { bold = true },
		normal_fg = { fg = "black" },
	}

	function hl.adaptive_bg()
		return {
			bg = conditions.is_active() and "gray" or "white",
			force = true,
		}
	end

	function hl.filename(self)
		local hl_table = vim.tbl_extend("force", hl.adaptive_bg(), hl.normal_fg, hl.bold)
		if self.is_modified then
			hl_table.fg = "constant_fg"
		end
		return hl_table
	end

	local FileName = {
		block = {
			init = function(self)
				self.filename = vim.api.nvim_buf_get_name(0)
				self.relative_filename = vim.fn.fnamemodify(self.filename, ":.")
				self.relative_dir = vim.fn.fnamemodify(self.filename, ":.:h")
				self.tail_filename = vim.fn.fnamemodify(self.filename, ":t")
				self.tail_root_filename = vim.fn.fnamemodify(self.filename, ":t:r")
				self.is_modified = vim.bo.modified
				self.is_readonly = not vim.bo.modifiable or vim.bo.readonly
				self.is_unnamed = self.relative_filename == ""
				self.is_newfile = self.relative_filename ~= ""
					and vim.bo.buftype == ""
					and vim.fn.filereadable(self.relative_filename) == 0
			end,
		},
	}

	FileName.relative_dir = {
		provider = function(self)
			return self.relative_dir ~= "." and self.relative_dir .. "/"
		end,
	}

	FileName.hydra = {
		condition = function()
			return conditions.is_active()
				and package.loaded.hydra
				and require("hydra.statusline").is_active()
				and require("hydra.statusline").get_name()
		end,
		hl = function()
			return vim.tbl_extend("force", hl.adaptive_bg(), hl.bold, { fg = "diag_info" })
		end,
		provider = function(self)
			return self.tail_filename
		end,
	}

	FileName.tail = {
		fallthrough = false,
		FileName.hydra,
		{
			provider = function(self)
				return self.tail_filename
			end,
			hl = hl.filename,
		},
	}

	FileName.tail_root = {
		provider = function(self)
			return self.tail_root_filename
		end,
		hl = hl.filename,
	}

	FileName.tail_by_ft = {
		condition = function()
			return conditions.buffer_matches({
				filetype = { "DiffviewFiles", "DiffviewFileHistory", "spectre_panel" },
			})
		end,
		provider = function(self)
			return self.tail_filename
		end,
	}

	FileName.truncated = {
		condition = function(self)
			return self.relative_filename:match("^diffview") or self.relative_filename:match("^fugitive")
		end,
		provider = function(self)
			return require("user.utils").hide_long_path(self.relative_filename)
		end,
	}

	FileName.neotree = {
		condition = function()
			return vim.bo.filetype == "neo-tree"
		end,
		CutHere,
		{
			provider = function()
				return vim.fn.fnamemodify(vim.fn.getcwd(), ":~:h") .. "/"
			end,
		},
		{
			provider = function()
				return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
			end,
			hl = function()
				return vim.tbl_extend("force", hl.adaptive_bg(), hl.bold, hl.normal_fg)
			end,
		},
	}

	FileName.oil = {
		condition = function()
			return package.loaded.oil and conditions.buffer_matches({ filetype = { "oil" } })
		end,
		CutHere,
		{
			provider = function()
				return vim.fn.fnamemodify(require("oil").get_current_dir(), ":~")
			end,
		},
	}

	FileName.qf = {
		condition = function()
			return vim.bo.filetype == "qf"
		end,
		{ provider = "%q" },
		Space,
		{
			provider = function()
				local is_loclist = vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0
				return is_loclist and vim.fn.getloclist(0, { title = 0 }).title or vim.fn.getqflist({ title = 0 }).title
			end,
			hl = hl.normal_fg,
		},
	}

	FileName.fugitive_branch = {
		init = function(self)
			self.git_branch_name = vim.fn.FugitiveHead()
		end,
		condition = function()
			return vim.bo.filetype == "fugitive"
		end,
		static = { git_branch_icon = " " },
		hl = hl.filename,
		flexible = 3,
		{
			provider = function(self)
				return self.git_branch_icon .. self.git_branch_name
			end,
		},
		{
			provider = function(self)
				return self.git_branch_name
			end,
		},
	}

	FileName.help = {
		condition = function()
			return conditions.buffer_matches({
				filetype = { "help" },
				buftype = { "help" },
			})
		end,
		provider = function(self)
			return self.tail_filename
		end,
		hl = function()
			return vim.tbl_extend("force", hl.adaptive_bg(), hl.bold, hl.normal_fg)
		end,
	}

	FileName.plain = {
		flexible = 3,
		{ FileName.relative_dir, FileName.tail },
		FileName.tail,
		FileName.tail_root,
	}

	FileName.flags = {
		block = {
			condition = function()
				return not conditions.buffer_matches({
					---@diagnostic disable-next-line: missing-parameter
					filetype = vim.list_extend({ "fugitive", "qf" }, ft_to_hide_compass_and_flag),
					buftype = { "nofile" },
				})
			end,
			static = {
				modified_icon = "⏺", -- [+]  ⏺
				readonly_icon = "",
				unnamed_icon = "[No Name]",
				newfile_icon = "", -- [New] 
			},
			hl = hl.adaptive_bg,
		},
	}

	FileName.flags.modified = {
		condition = function(self)
			return self.is_modified
		end,
		Space,
		{
			provider = function(self)
				return self.modified_icon
			end,
			hl = { fg = "constant_fg" },
		},
	}

	FileName.flags.readonly = {
		condition = function(self)
			return self.is_readonly
		end,
		Space,
		{
			provider = function(self)
				return self.readonly_icon
			end,
			hl = { fg = "diag_error" },
		},
	}

	FileName.flags.unnamed = {
		condition = function(self)
			return self.is_unnamed
		end,
		Space,
		{
			provider = function(self)
				return self.unnamed_icon
			end,
		},
	}

	FileName.flags.newfile = {
		condition = function(self)
			return self.is_newfile
		end,
		hl = { fg = "special_fg" },
		Space,
		{
			provider = function(self)
				return self.newfile_icon
			end,
		},
	}

	FileName.flags.block = utils.insert(
		FileName.flags.block,
		FileName.flags.modified,
		FileName.flags.readonly,
		FileName.flags.unnamed,
		FileName.flags.newfile
	)

	FileName.block = utils.insert(
		FileName.block,
		utils.insert(
			{ fallthrough = false },
			FileName.fugitive_branch,
			FileName.tail_by_ft,
			FileName.truncated,
			FileName.neotree,
			FileName.oil,
			FileName.qf,
			FileName.help,
			FileName.plain
		),
		FileName.flags.block,
		CutHere
	)

	local Diff = {
		block = {
			condition = conditions.is_git_repo,
			init = function(self)
				---@diagnostic disable-next-line: undefined-field
				self.status_dict = vim.b.gitsigns_status_dict
				self.has_changes = self.status_dict.added ~= 0
					or self.status_dict.removed ~= 0
					or self.status_dict.changed ~= 0
			end,
		},
	}

	Diff.added = {
		provider = function(self)
			local count = self.status_dict.added or 0
			return count > 0 and ("+" .. count)
		end,
	}

	Diff.removed = {
		provider = function(self)
			local count = self.status_dict.removed or 0
			return count > 0 and ("-" .. count)
		end,
	}

	Diff.changed = {
		provider = function(self)
			local count = self.status_dict.changed or 0
			return count > 0 and ("~" .. count)
		end,
	}

	Diff.block = utils.insert(
		Diff.block,
		{
			condition = function(self)
				return self.has_changes
					and (self.status_dict.added or self.status_dict.removed or self.status_dict.changed)
			end,
			provider = "(",
		},
		Diff.added,
		Diff.removed,
		Diff.changed,
		{
			condition = function(self)
				return self.has_changes
					and (self.status_dict.added or self.status_dict.removed or self.status_dict.changed)
			end,
			provider = ")",
		}
	)

	local Diagnostic = {
		block = {
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
		},
	}

	Diagnostic.error = {
		provider = function(self)
			return self.errors > 0 and (self.error_icon .. self.errors .. " ")
		end,
		hl = { fg = "diag_error" },
	}

	Diagnostic.warning = {
		provider = function(self)
			return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
		end,
		hl = { fg = "diag_warn" },
	}

	Diagnostic.info = {
		provider = function(self)
			return self.info > 0 and (self.info_icon .. self.info .. " ")
		end,
		hl = { fg = "diag_info" },
	}

	Diagnostic.hint = {
		provider = function(self)
			return self.hints > 0 and (self.hint_icon .. self.hints)
		end,
		hl = { fg = "diag_hint" },
	}

	Diagnostic.block =
		utils.insert(Diagnostic.block, Diagnostic.error, Diagnostic.warning, Diagnostic.info, Diagnostic.hint)

	local Compass = {
		ruler = { provider = "%(%l/%L%):%c" },
		scrollBar = {
			static = { sbar = { "🭶", "🭷", "🭸", "🭹", "🭺", "🭻" } },
			provider = function(self)
				local curr_line = vim.api.nvim_win_get_cursor(0)[1]
				local lines = vim.api.nvim_buf_line_count(0)
				local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
				return string.rep(self.sbar[i], 2)
			end,
		},
	}

	Compass.block = {
		condition = function()
			if vim.bo.filetype == "neo-tree" then
				return false
			end
			return not conditions.buffer_matches({
				filetype = ft_to_hide_compass_and_flag,
			})
		end,
		flexible = 2,
		{ Space, Compass.ruler, Space, Compass.scrollBar },
		{ Compass.scrollBar },
		{},
	}

	local Tab = {
		page = {
			provider = function(self)
				return "%" .. self.tabpage .. "T " .. self.tabnr .. " %T"
			end,
			hl = function(self)
				return self.is_active and "TabLineSel" or "TabLine"
			end,
		},
	}

	Tab.block = {
		condition = function()
			return #vim.api.nvim_list_tabpages() >= 2
		end,
		utils.make_tablist(Tab.page),
	}

	require("heirline").setup({
		statusline = {
			Space,
			FileName.block,
			Space,
			utils.insert({ flexible = 1 }, { Diff.block, Space, Diagnostic.block }, { Diagnostic.block }, {}),
			Align,
			Compass.block,
			Space,
		},
		tabline = { Align, Tab.block },
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
