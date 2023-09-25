local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local lib = require("nvim-config-lib.heirline.lib")
local ft_to_hide_compass_and_flag = lib.ft_to_hide_compass_and_flag
local Space = lib.Space
local CutHere = lib.CutHere
local hl = lib.hl

local M = {}

M.block = {
	init = function(self)
		self.filename = vim.api.nvim_buf_get_name(0)
		self.relative_filename = vim.fn.fnamemodify(self.filename, ":.")
		self.relative_dir = vim.fn.fnamemodify(self.filename, ":~:.:h")
		self.tail_filename = vim.fn.fnamemodify(self.filename, ":t")
		self.tail_root_filename = vim.fn.fnamemodify(self.filename, ":t:r")
		self.is_modified = vim.bo.modified
		self.is_readonly = not vim.bo.modifiable or vim.bo.readonly
		self.is_unnamed = self.relative_filename == ""
		self.is_newfile = self.relative_filename ~= ""
			and vim.bo.buftype == ""
			and vim.fn.filereadable(self.relative_filename) == 0
	end,
}

M.relative_dir = {
	provider = function(self)
		return self.is_unnamed and "" or self.relative_dir ~= "." and self.relative_dir .. "/"
	end,
}

M.relative_dir_shorten = {
	{
		provider = function(self)
			local relative_dir_shorten = vim.fn.pathshorten(self.relative_dir)
			return self.is_unnamed and "" or relative_dir_shorten ~= "." and relative_dir_shorten .. "/"
		end,
	},
	{
		provider = function(self)
			local relative_dir_shorten = vim.fn.pathshorten(self.relative_dir, 2)
			return self.is_unnamed and "" or relative_dir_shorten ~= "." and relative_dir_shorten .. "/"
		end,
	},
}

M.hydra = {
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

M.tail = {
	fallthrough = false,
	M.hydra,
	{
		provider = function(self)
			return self.tail_filename
		end,
		hl = hl.filename,
	},
}

M.tail_root = {
	provider = function(self)
		return self.tail_root_filename
	end,
	hl = hl.filename,
}

M.tail_by_ft = {
	condition = function()
		return conditions.buffer_matches({
			filetype = { "DiffviewFiles", "DiffviewFileHistory", "spectre_panel" },
		})
	end,
	provider = function(self)
		return self.tail_filename
	end,
}

M.truncated = {
	condition = function(self)
		return self.relative_filename:match("^diffview") or self.relative_filename:match("^fugitive")
	end,
	provider = function(self)
		return require("user.utils").hide_long_path(self.relative_filename)
	end,
}

M.neotree = {
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

M.oil = {
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

M.qf = {
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

M.fugitive_branch = {
	init = function(self)
		self.git_branch_name = vim.fn.FugitiveHead()
	end,
	condition = function()
		return vim.bo.filetype == "fugitive"
	end,
	static = { git_branch_icon = lib.options.nerd_fonts and " " or "" },
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

M.help = {
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

M.plain = {
	flexible = 3,
	{ M.relative_dir, M.tail },
	{ M.relative_dir_shorten[2], M.tail },
	{ M.relative_dir_shorten[1], M.tail },
	M.tail,
	M.tail_root,
}

M.flags = {
	block = {
		condition = function()
			return not conditions.buffer_matches({
				---@diagnostic disable-next-line: missing-parameter
				filetype = vim.list_extend({ "fugitive", "qf" }, ft_to_hide_compass_and_flag),
				buftype = { "nofile" },
			})
		end,
		static = {
			modified_icon = lib.options.nerd_fonts and "⏺" or "[+]", -- [+]  ⏺
			readonly_icon = lib.options.nerd_fonts and "" or "[RO]",
			unnamed_icon = "[No Name]",
			newfile_icon = lib.options.nerd_fonts and "" or "[New]", -- [New] 
		},
		hl = hl.adaptive_bg,
	},
}

M.flags.modified = {
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

M.flags.readonly = {
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

M.flags.unnamed = {
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

M.flags.newfile = {
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

M.flags.block = utils.insert(M.flags.block, M.flags.modified, M.flags.readonly, M.flags.unnamed, M.flags.newfile)

M.block = utils.insert(
	M.block,
	utils.insert(
		{ fallthrough = false },
		M.fugitive_branch,
		M.tail_by_ft,
		M.truncated,
		M.neotree,
		M.oil,
		M.qf,
		M.help,
		M.plain
	),
	M.flags.block,
	CutHere
)

return M
