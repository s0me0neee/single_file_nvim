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
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250
vim.opt.confirm = true
vim.opt.wildmode = "noselect:lastused,full"
vim.opt.wildoptions:append("fuzzy")
require("vim._core.ui2").enable()

-- bun and its global packages (tsc) live here; non-login shells often lack it on PATH
local bun_bin = vim.fn.expand("~/.bun/bin")
if vim.fn.isdirectory(bun_bin) == 1 and not vim.env.PATH:find(bun_bin, 1, true) then
	vim.env.PATH = bun_bin .. ":" .. vim.env.PATH
end

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

	-- blink's select_and_accept: accept the selected item, or the first one
	vim.keymap.set("i", "<CR>", function()
		if vim.fn.pumvisible() == 1 then
			return vim.fn.complete_info({ "selected" }).selected == -1 and "<Down><C-y>" or "<C-y>"
		end
		local p = prev_char()
		if p:match("[%(%[{]") and ap[p] == next_char() then
			return "<CR><Esc>O"
		end
		return "<CR>"
	end, { expr = true })
end

local map = vim.keymap.set

-- editing
map("n", "<Esc>", function()
	vim.cmd("noh")
	vim.snippet.stop()
	return "<Esc>"
end, { expr = true })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("n", "<A-j>", "<Cmd>m .+1<CR>==")
map("n", "<A-k>", "<Cmd>m .-2<CR>==")
map("i", "<A-j>", "<Esc><Cmd>m .+1<CR>==gi")
map("i", "<A-k>", "<Esc><Cmd>m .-2<CR>==gi")
map("x", "<A-j>", ":m '>+1<CR>gv=gv", { silent = true })
map("x", "<A-k>", ":m '<-2<CR>gv=gv", { silent = true })
map("x", "<", "<gv")
map("x", ">", ">gv")
map("n", "<leader>-", "<Cmd>split<CR>")
map("n", "<leader>|", "<Cmd>vsplit<CR>")
map("n", "<leader>wd", "<Cmd>close<CR>")
map("n", "<leader>bd", function()
	local buf = vim.api.nvim_get_current_buf()
	vim.cmd("bprevious")
	if vim.api.nvim_get_current_buf() == buf then
		vim.cmd("enew")
	end
	vim.cmd("confirm bdelete " .. buf)
end)
-- only y and d fill the unnamed register; an explicitly named one is still honored
for _, key in ipairs({ "c", "C", "x", "X" }) do
	map({ "n", "x" }, key, function()
		return vim.v.register == '"' and '"_' .. key or key
	end, { expr = true })
end
map("x", "p", "P")
-- substitute word under cursor; 'inccommand' previews it live
map({ "n", "x" }, "<leader>R", function()
	local word = vim.fn.escape(vim.fn.expand("<cword>"), [[\/]])
	local range = vim.fn.mode() == "n" and "%" or ""
	return ":" .. range .. [[s/\V\<]] .. word .. [[\>//g<Left><Left>]]
end, { expr = true })

-- find files / grep with the built-in cmdline popup
local file_cache
function _G.FindFiles(arg)
	if not file_cache then
		local cmd = vim.fn.executable("rg") == 1 and { "rg", "--files", "--hidden", "-g", "!.git" }
			or vim.fn.executable("fd") == 1 and { "fd", "-t", "f", "-H", "-E", ".git" }
			or vim.fn.executable("fdfind") == 1 and { "fdfind", "-t", "f", "-H", "-E", ".git" }
		file_cache = cmd and vim.fn.systemlist(cmd)
			or vim.tbl_filter(function(f)
				return vim.fn.isdirectory(f) == 0
			end, vim.fn.glob("**/*", false, true))
	end
	return arg == "" and file_cache or vim.fn.matchfuzzy(file_cache, arg)
end
vim.opt.findfunc = "v:lua.FindFiles"
if vim.fn.executable("rg") == 1 then
	vim.opt.grepprg = "rg --vimgrep --smart-case --hidden -g !.git"
end
vim.api.nvim_create_autocmd("CmdlineChanged", { pattern = ":", command = "call wildtrigger()" })
vim.api.nvim_create_autocmd("CmdlineLeave", {
	callback = function()
		file_cache = nil
	end,
})
vim.api.nvim_create_autocmd("QuickFixCmdPost", { pattern = "[^l]*", command = "cwindow" })
map("c", "<Up>", function()
	return vim.fn.wildmenumode() == 1 and "<C-e><Up>" or "<Up>"
end, { expr = true })
map("c", "<Down>", function()
	return vim.fn.wildmenumode() == 1 and "<C-e><Down>" or "<Down>"
end, { expr = true })
map("n", "<leader><space>", ":find ")
map("n", "<leader>ff", ":find ")
map("n", "<leader>fb", ":buffer ")
map("n", "<leader>sg", ":silent grep! ")
map("n", "<leader>sw", function()
	vim.cmd("silent grep! -w " .. vim.fn.shellescape(vim.fn.expand("<cword>")))
end)
map("n", "<leader>xx", vim.diagnostic.setqflist)

-- toggleable bottom terminal; <C-_> is what most terminals send for <C-/>
local term = { buf = -1, win = -1 }
local function toggle_term()
	if vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_hide(term.win)
		return
	end
	vim.cmd("botright split")
	vim.api.nvim_win_set_height(0, math.floor(vim.o.lines * 0.3))
	term.win = vim.api.nvim_get_current_win()
	if vim.api.nvim_buf_is_valid(term.buf) then
		vim.api.nvim_win_set_buf(term.win, term.buf)
	else
		vim.cmd.terminal()
		term.buf = vim.api.nvim_get_current_buf()
		vim.bo[term.buf].buflisted = false
	end
	vim.cmd.startinsert()
end
map({ "n", "t" }, "<C-/>", toggle_term)
map({ "n", "t" }, "<C-_>", toggle_term)
map("t", "<Esc><Esc>", "<C-\\><C-n>")

-- autocmds
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(ev)
		local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) and vim.bo[ev.buf].filetype ~= "gitcommit" then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(ev)
		if not ev.match:match("^%w%w+:[\\/][\\/]") then
			vim.fn.mkdir(vim.fn.fnamemodify(vim.uv.fs_realpath(ev.match) or ev.match, ":p:h"), "p")
		end
	end,
})
vim.api.nvim_create_autocmd("VimResized", { command = "tabdo wincmd =" })
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "help", "qf", "man", "checkhealth" },
	callback = function(ev)
		vim.bo[ev.buf].buflisted = false
		map("n", "q", "<Cmd>close<CR>", { buffer = ev.buf })
	end,
})
-- built-in treesitter highlighting wherever a parser is installed
vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		pcall(vim.treesitter.start, ev.buf)
	end,
})

-- LSP: TypeScript 7 native server, auto-attached by filetype
local ts_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }
vim.lsp.config("tsc", {
	cmd = { "tsc", "--lsp", "--stdio" },
	filetypes = ts_filetypes,
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})
vim.lsp.enable("tsc")

-- slow servers miss the graceful shutdown window and orphan
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		for _, client in ipairs(vim.lsp.get_clients()) do
			client:stop(true)
		end
	end,
})

-- bun fmt on save; applied as a diff so cursor, marks and undo stay sane
vim.g.autoformat = true
local function bun_fmt(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	local old = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
	local res = vim.system(
		{ "bun", "fmt", "--no-script", "--stdin-filepath=" .. name },
		{ stdin = old, cwd = vim.fs.dirname(name), text = true }
	):wait(5000)
	if res.code ~= 0 then
		local err = (res.stderr or ""):match("error:[^\n]*") or ("exit " .. res.code)
		vim.notify("bun fmt: " .. err, vim.log.levels.WARN)
		return
	end
	if res.stdout == old then
		return
	end
	local new = vim.split(res.stdout, "\n", { plain = true })
	if new[#new] == "" then
		table.remove(new)
	end
	local hunks = vim.text.diff(old, res.stdout, { result_type = "indices" })
	for i = #hunks, 1, -1 do
		local sa, ca, sb, cb = unpack(hunks[i])
		local start = ca == 0 and sa or sa - 1
		vim.api.nvim_buf_set_lines(buf, start, start + ca, false, vim.list_slice(new, sb, sb + cb - 1))
	end
end
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(ev)
		if
			vim.g.autoformat
			and vim.list_contains(ts_filetypes, vim.bo[ev.buf].filetype)
			and vim.fn.executable("bun") == 1
		then
			bun_fmt(ev.buf)
		end
	end,
})
map("n", "<leader>uf", function()
	vim.g.autoformat = not vim.g.autoformat
	vim.notify("format on save: " .. (vim.g.autoformat and "on" or "off"))
end)

-- blink-like completion menu (no plugin)
-- prefix matching keeps tsc's ranking (locals before DOM globals, map before flatMap); fuzzy loses it
vim.opt.completeopt = { "menuone", "noinsert", "popup" }
vim.opt.completeitemalign = "kind,abbr,menu"
vim.opt.pumheight = 10
vim.opt.shortmess:append("c")

-- ASCII kind markers (no Nerd Font): uppercase = type, lowercase = member
local kinds = {
	Class = { "C", "Type" },
	Interface = { "I", "Type" },
	Struct = { "S", "Type" },
	Enum = { "E", "Type" },
	TypeParameter = { "T", "Type" },
	Module = { "M", "Include" },
	Method = { "m", "Function" },
	Function = { "f", "Function" },
	Constructor = { "c", "Function" },
	Field = { "p", "Identifier" },
	Property = { "p", "Identifier" },
	Variable = { "v", "Identifier" },
	Constant = { "k", "Constant" },
	EnumMember = { "e", "Constant" },
	Value = { "v", "Constant" },
	Reference = { "r", "Identifier" },
	Event = { "!", "Identifier" },
	Unit = { "u", "Constant" },
	Color = { "#", "Constant" },
	Keyword = { "w", "Keyword" },
	Operator = { "o", "Operator" },
	Snippet = { "s", "Special" },
	Text = { "t", "Comment" },
	File = { "/", "Directory" },
	Folder = { "/", "Directory" },
}

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end
		local function bmap(mode, lhs, rhs, opts)
			map(mode, lhs, rhs, vim.tbl_extend("force", { buffer = ev.buf }, opts or {}))
		end
		bmap("n", "gd", vim.lsp.buf.definition)
		bmap("n", "gr", vim.lsp.buf.references, { nowait = true })
		bmap("n", "gI", vim.lsp.buf.implementation)
		bmap("n", "gy", vim.lsp.buf.type_definition)
		bmap("n", "gD", vim.lsp.buf.declaration)
		bmap({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action)
		bmap("n", "<leader>cr", vim.lsp.buf.rename)
		bmap("n", "<leader>cd", vim.diagnostic.open_float)
		bmap("n", "<leader>uh", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
		end)

		if client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
		end
		if client:supports_method("textDocument/documentHighlight") then
			local group = vim.api.nvim_create_augroup("lsp_highlight_" .. ev.buf, { clear = true })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = ev.buf,
				group = group,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = ev.buf,
				group = group,
				callback = vim.lsp.buf.clear_references,
			})
		end

		if not client:supports_method("textDocument/completion") then
			return
		end
		-- tsc's bracket members ("[Symbol]") edit over the ".", which drags the menu's start onto
		-- the dot so nothing matches once you type; drop them
		if client.name == "tsc" and not client._drop_bracket_items then
			client._drop_bracket_items = true
			local request = client.request
			client.request = function(self, method, params, handler, bufnr)
				if method == "textDocument/completion" and handler then
					local inner = handler
					handler = function(err, result, ...)
						local items = type(result) == "table" and (result.items or result) or {}
						for i = #items, 1, -1 do
							local edit = items[i].textEdit
							if edit and (edit.newText or ""):sub(1, 1) == "[" then
								table.remove(items, i)
							end
						end
						return inner(err, result, ...)
					end
				end
				return request(self, method, params, handler, bufnr)
			end
		end
		-- open on identifier keystrokes too; tsc rejects extra triggerCharacters
		vim.api.nvim_create_autocmd("InsertCharPre", {
			buffer = ev.buf,
			group = vim.api.nvim_create_augroup("lsp_autocomplete_" .. ev.buf, { clear = true }),
			callback = function()
				if vim.v.char:match("[%w_$]") and vim.fn.pumvisible() == 0 then
					vim.schedule(vim.lsp.completion.get)
				end
			end,
		})

		vim.lsp.completion.enable(true, client.id, ev.buf, {
			autotrigger = true,
			convert = function(item)
				local kind = kinds[vim.lsp.protocol.CompletionItemKind[item.kind]] or kinds.Text
				return { kind = kind[1], kind_hlgroup = kind[2], menu = "" }
			end,
		})
	end,
})

-- blink keymap: <C-j>/<C-k>/<Down>/<Up> select without inserting or wrapping, <C-e> toggles;
-- <Tab> snippet-forward is Neovim's default
local function pum_move(dir, fallback)
	return function()
		if vim.fn.pumvisible() == 0 then
			return fallback
		end
		local info = vim.fn.complete_info({ "selected", "items" })
		local target = info.selected + dir
		if target < 0 or target >= #info.items then
			return ""
		end
		return dir > 0 and "<Down>" or "<Up>"
	end
end
map("i", "<C-j>", pum_move(1, ""), { expr = true })
map("i", "<C-k>", pum_move(-1, ""), { expr = true })
map("i", "<Down>", pum_move(1, "<Down>"), { expr = true })
map("i", "<Up>", pum_move(-1, "<Up>"), { expr = true })
map("i", "<C-e>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-e>"
	end
	if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" }) > 0 then
		return "<Cmd>lua vim.lsp.completion.get()<CR>"
	end
	return "<C-n>"
end, { expr = true })

-- true when every signature in texts shows an empty "()" right after label
local function takes_no_params(label, texts)
	local found = false
	for _, s in ipairs(texts) do
		if type(s) == "string" then
			local init = 1
			while true do
				local b, e = s:find(label, init, true)
				if not b then
					break
				end
				init = e + 1
				-- "strip" inside "rstrip()" isn't this function
				if b == 1 or not s:sub(b - 1, b - 1):match("[%w_$]") then
					local after = s:sub(e + 1):gsub("^%b<>", "")
					if after:match("^%(%)") then
						found = true
					elseif after:match("^%(") then
						return false
					end
				end
			end
		end
	end
	return found
end

-- blink's auto_brackets: add "()" after functions, cursor inside only when it takes params
vim.api.nvim_create_autocmd("CompleteDone", {
	callback = function()
		if vim.v.event.reason ~= "accept" then
			return
		end
		local data = vim.tbl_get(vim.v.completed_item, "user_data", "nvim", "lsp") or {}
		local item = data.completion_item
		local kind = item and item.kind
		if not kind or kind < 2 or kind > 4 or item.insertTextFormat == 2 then
			return
		end
		local line, col = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2]
		if line:sub(col + 1, col + 1) == "(" or line:match("^%s*import") or line:match("^%s*export%s*{") then
			return
		end
		-- tsc only sends the signature after resolve
		local client = vim.lsp.get_client_by_id(data.client_id)
		local res = client and client:request_sync("completionItem/resolve", item, 300, 0)
		local resolved = res and res.result or item
		local texts = {
			resolved.detail,
			vim.tbl_get(resolved, "labelDetails", "detail"),
			vim.tbl_get(resolved, "labelDetails", "description"),
		}
		local keys = takes_no_params(item.label, texts) and "()" or "()<C-g>U<Left>"
		vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
	end,
})

-- error lens: tinted line + message at end of line
local function blend(fg, bg, alpha)
	local out = 0
	for _, shift in ipairs({ 65536, 256, 1 }) do
		local f, b = math.floor(fg / shift) % 256, math.floor(bg / shift) % 256
		out = out + math.floor(f * alpha + b * (1 - alpha) + 0.5) * shift
	end
	return out
end

local function errorlens_hl()
	local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
		or (vim.o.background == "light" and 0xffffff or 0x000000)
	for _, s in ipairs({ "Error", "Warn", "Info", "Hint" }) do
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
	virtual_text = { prefix = "", spacing = 4, source = "if_many" },
	signs = {
		linehl = {
			[S.ERROR] = "ErrorLensError",
			[S.WARN] = "ErrorLensWarn",
			[S.INFO] = "ErrorLensInfo",
			[S.HINT] = "ErrorLensHint",
		},
	},
	float = { border = "single", source = "if_many" },
})
