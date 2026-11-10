vim.g.bigfile_disable = false
vim.g.mapleader = " "
vim.opt.autoindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = false
vim.opt.expandtab = false
vim.opt.laststatus = 0
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.softtabstop = 4
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.wildmenu = true
vim.opt.cursorline = true
vim.cmd("language ja_JP")
require("vim._core.ui2").enable()

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({
			timeout = 500, -- Duration in milliseconds
			higroup = "IncSearch", -- Highlight group to use (default is IncSearch)
		})
	end,
})
vim.keymap.set("n", "L", ":bnext<CR>", { silent = true })
vim.keymap.set("n", "H", ":bprev<CR>", { silent = true })
vim.keymap.set("n", "<Leader>e", ":Ex<CR>", { silent = true })

-- vim.pack.add({ { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } })
-- vim.cmd.colorscheme("catppuccin-nvim")

function MyBufferLine()
	local s = ""
	for i, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
			if bufnr == vim.api.nvim_get_current_buf() then
				s = s .. "%#TabLineSel#"
			else
				s = s .. "%#TabLine#"
			end

			local name = vim.api.nvim_buf_get_name(bufnr)
			if name == "" then
				name = "[No Name]"
			else
				name = fnamemodify(name, ":t")
			end
			s = s .. " " .. bufnr .. ":" .. name .. " "
		end
	end
	return s .. "%#TabLineFill#%T"
end

function fnamemodify(path, modifier)
	return vim.fn.fnamemodify(path, modifier)
end

vim.opt.tabline = "%!v:lua.MyBufferLine()"
vim.opt.showtabline = 2

-- autopairs (no plugin)
do
	local ap = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["`"] = "`" }

	local function next_char()
		local c = vim.fn.col(".")
		return vim.fn.getline("."):sub(c, c)
	end
	local function prev_char()
		local c = vim.fn.col(".")
		return vim.fn.getline("."):sub(c - 1, c - 1)
	end

	local L, R = "<C-g>U<Left>", "<C-g>U<Right>"

	for open, close in pairs(ap) do
		if open ~= close then
			vim.keymap.set("i", open, open .. close .. L)
			vim.keymap.set("i", close, function()
				return next_char() == close and R or close
			end, { expr = true })
		else
			vim.keymap.set("i", open, function()
				if next_char() == open then
					return R
				end
				if prev_char():match("%w") then
					return open
				end
				if open == "'" and vim.bo.filetype == "rust" then
					return open
				end -- lifetimes
				return open .. open .. L
			end, { expr = true })
		end
	end

	vim.keymap.set("i", "<BS>", function()
		local p = prev_char()
		return (ap[p] and ap[p] == next_char()) and "<BS><Del>" or "<BS>"
	end, { expr = true })

	vim.keymap.set("i", "<CR>", function()
		local p = prev_char()
		if p:match("[%(%[{]") and ap[p] == next_char() then
			return "<CR><Esc>O"
		end
		return "<CR>"
	end, { expr = true })
end
