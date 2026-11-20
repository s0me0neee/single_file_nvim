vim.g.bigfile_disable = false
vim.g.mapleader = " "
vim.opt.autoindent = true
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
		if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
			return "<C-y>"
		end
		local p = prev_char()
		if p:match("[%(%[{]") and ap[p] == next_char() then
			return "<CR><Esc>O"
		end
		return "<CR>"
	end, { expr = true })
end

-- LSP: TypeScript 7 native server, auto-attached by filetype
vim.lsp.config("tsc", {
	cmd = { "tsc", "--lsp", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})
vim.lsp.enable("tsc")

-- blink-like completion menu (no plugin)
vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }
vim.opt.pumborder = "rounded"
vim.opt.pumheight = 12
vim.opt.pummaxwidth = 60
vim.opt.shortmess:append("c")

local kind_icons = {
	Text = "\u{eb8d}", Method = "\u{ea8c}", Function = "\u{ea8c}", Constructor = "\u{ea8c}",
	Field = "\u{eb5f}", Variable = "\u{ea88}", Class = "\u{eb5b}", Interface = "\u{eb61}",
	Module = "\u{ea8b}", Property = "\u{eb65}", Unit = "\u{ea96}", Value = "\u{ea90}",
	Enum = "\u{ea95}", Keyword = "\u{eb62}", Snippet = "\u{eb66}", Color = "\u{eb5c}",
	File = "\u{eb60}", Reference = "\u{eb36}", Folder = "\u{ea83}", EnumMember = "\u{eb5e}",
	Constant = "\u{eb5d}", Struct = "\u{ea91}", Event = "\u{ea86}", Operator = "\u{eb64}",
	TypeParameter = "\u{ea92}",
}

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or not client:supports_method("textDocument/completion") then
			return
		end
		-- trigger on every identifier keystroke, not just "." etc.
		local provider = client.server_capabilities.completionProvider
		local chars = provider.triggerCharacters or {}
		for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$"):gmatch(".") do
			table.insert(chars, c)
		end
		provider.triggerCharacters = chars

		vim.lsp.completion.enable(true, client.id, ev.buf, {
			autotrigger = true,
			convert = function(item)
				local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Text"
				return {
					abbr = item.label:gsub("%b()", ""),
					kind = (kind_icons[kind] or "") .. " " .. kind,
					kind_hlgroup = "Special",
					menu = item.labelDetails and item.labelDetails.description or "",
				}
			end,
		})
	end,
})

vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get)
vim.keymap.set({ "i", "s" }, "<Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-n>"
	elseif vim.snippet.active({ direction = 1 }) then
		return "<Cmd>lua vim.snippet.jump(1)<CR>"
	end
	return "<Tab>"
end, { expr = true })
vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-p>"
	elseif vim.snippet.active({ direction = -1 }) then
		return "<Cmd>lua vim.snippet.jump(-1)<CR>"
	end
	return "<S-Tab>"
end, { expr = true })

-- error lens: tinted line + message at end of line
local function blend(fg, bg, alpha)
	local out = 0
	for _, shift in ipairs({ 65536, 256, 1 }) do
		local f, b = math.floor(fg / shift) % 256, math.floor(bg / shift) % 256
		out = out + math.floor(f * alpha + b * (1 - alpha) + 0.5) * shift
	end
	return out
end

local severities = { "Error", "Warn", "Info", "Hint" }

local function errorlens_hl()
	local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
		or (vim.o.background == "light" and 0xffffff or 0x000000)
	for _, s in ipairs(severities) do
		local fg = vim.api.nvim_get_hl(0, { name = "Diagnostic" .. s, link = false }).fg
		if fg then
			vim.api.nvim_set_hl(0, "ErrorLens" .. s, { bg = blend(fg, bg, 0.12) })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualText" .. s, { fg = fg, bg = blend(fg, bg, 0.2) })
		end
	end
end
errorlens_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = errorlens_hl })

local S = vim.diagnostic.severity
vim.diagnostic.config({
	severity_sort = true,
	virtual_text = { prefix = "●", spacing = 4, source = "if_many" },
	signs = {
		linehl = {
			[S.ERROR] = "ErrorLensError",
			[S.WARN] = "ErrorLensWarn",
			[S.INFO] = "ErrorLensInfo",
			[S.HINT] = "ErrorLensHint",
		},
	},
	float = { border = "rounded", source = "if_many" },
})
