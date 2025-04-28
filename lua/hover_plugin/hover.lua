local M = {}

M.setup = function()
	-- Set general Neovim options for number width, sign column, and status column
	vim.opt.numberwidth = 3
	vim.opt.signcolumn = "yes:1"
	vim.opt.statuscolumn = "%l%s"
	vim.opt.updatetime = 1000

	-- -- Define diagnostic signs in the sign column
	-- vim.fn.sign_define("DiagnosticSignError", { text = "●", texthl = "DiagnosticError" })
	-- vim.fn.sign_define("DiagnosticSignWarn", { text = "●", texthl = "DiagnosticWarn" })
	-- vim.fn.sign_define("DiagnosticSignHint", { text = "●", texthl = "DiagnosticHint" })
	-- vim.fn.sign_define("DiagnosticSignInfo", { text = "●", texthl = "DiagnosticInfo" })
	--
	-- -- Noice.nvim setup for handling hover
	-- require("noice").setup({
	-- 	opts = {
	-- 		routes = {
	-- 			{
	-- 				filter = {
	-- 					event = "notify",
	-- 					find = "method textDocument/hover is not supported",
	-- 				},
	-- 				opts = { skip = true },
	-- 			},
	-- 			{
	-- 				filter = {
	-- 					event = "notify",
	-- 					find = "position_encoding param is required",
	-- 				},
	-- 				opts = { skip = true },
	-- 			},
	-- 		},
	-- 		notify = {
	-- 			enabled = false,
	-- 			view = "notify",
	-- 		},
	-- 		views = {
	-- 			lsp_popup_dynamic = {
	-- 				backend = "popup",
	-- 				size = {
	-- 					width = "auto", -- grow with content
	-- 					height = "auto", -- grow with content
	-- 					max_width = math.floor(vim.o.columns * 0.5), -- maximum 50% of screen width
	-- 					max_height = math.floor(vim.o.lines * 0.3), -- maximum 30% of screen height
	-- 				},
	-- 				border = {
	-- 					style = "rounded",
	-- 				},
	-- 				position = {
	-- 					row = 1,
	-- 					col = 0,
	-- 				},
	-- 				win_options = {
	-- 					wrap = true, -- Wrap long lines automatically
	-- 					linebreak = true, -- Break at word boundaries, not mid-word
	-- 					winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
	-- 					winblend = 10,
	-- 				},
	-- 			},
	-- 		},
	-- 		lsp = {
	-- 			progress = {
	-- 				enabled = true,
	-- 				format = "lsp_progress",
	-- 				format_done = "lsp_progress_done",
	-- 				throttle = 1000 / 30,
	-- 				view = "mini",
	-- 			},
	-- 			override = {
	-- 				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
	-- 				["vim.lsp.util.stylize_markdown"] = true,
	-- 				["cmp.entry.get_documentation"] = true,
	-- 			},
	-- 			hover = {
	-- 				enabled = true,
	-- 				silent = true,
	-- 				view = "lsp_popup_dynamic", -- our new view
	-- 				opts = {}, -- use view's settings
	-- 			},
	-- 			signature = {
	-- 				enabled = true,
	-- 				auto_open = {
	-- 					enabled = true,
	-- 					trigger = true,
	-- 					luasnip = true,
	-- 					throttle = 50,
	-- 				},
	-- 				view = nil,
	-- 				opts = {},
	-- 			},
	-- 			message = {
	-- 				enabled = true,
	-- 				view = "notify",
	-- 				opts = {},
	-- 			},
	-- 			documentation = {
	-- 				view = "lsp_popup_dynamic", -- consistent view for hover + docs
	-- 				opts = {
	-- 					replace = true,
	-- 					render = "plain", --"markdown"
	-- 					win_options = {
	-- 						wrap = true,
	-- 						linebreak = true,
	-- 						concealcursor = "n",
	-- 						conceallevel = 3,
	-- 					},
	-- 					style = "minimal",
	-- 					border = "rounded",
	-- 					relative = "cursor",
	-- 					anchor = "SW",
	-- 					row = -1,
	-- 					col = 0,
	-- 				},
	-- 			},
	-- 		},
	-- 	},
	-- })
	--
	-- Configure diagnostics
	vim.diagnostic.config({
		virtual_text = false, -- no inline diagnostics
		signs = true, -- keep signs in the gutter
		underline = true, -- underline problem text
		update_in_insert = false,
		severity_sort = true,
		float = {
			border = "rounded",
			max_width = math.floor(vim.o.columns * 0.5), -- maximum 50% of screen width
			max_height = math.floor(vim.o.lines * 0.3), -- maximum 30% of screen height
			wrap = true,
			focusable = false,
			style = "minimal",
			relative = "cursor",
			anchor = "NW",
			row = -10,
			col = 0,
			source = true,
		},
	})

	-- Custom handler to prevent hover popups from focusing
	vim.lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
		-- Prevent focus on hover popups
		local opts = { focusable = false, border = "rounded" }
		if result and result.contents then
			vim.lsp.util.open_floating_preview(result.contents, "markdown", opts)
		end
	end

	-- Autocmd for diagnostic popup
	vim.api.nvim_create_autocmd("CursorHold", {
		callback = function()
			if vim.fn.mode() == "n" then
				local diags = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
				if #diags > 0 then
					vim.diagnostic.open_float(nil, { focus = false, border = "rounded" })
				end
				-- Trigger the custom hover handler for hover popups
				vim.lsp.buf.hover()
			end
		end,
	})

	-- Function to close small hover popups (only in normal mode)
	local function close_hover_or_small_float_windows()
		if vim.fn.mode() == "n" then
			-- Check if currently focused window is floating
			local curr_win = vim.api.nvim_get_current_win()
			local ok, curr_conf = pcall(vim.api.nvim_win_get_config, curr_win)
			if ok and curr_conf and curr_conf.relative ~= "" then
				return -- Focused inside float, don't close anything
			end
			-- Close small floating hovers if not focused and window is small
			for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				local ok, config = pcall(vim.api.nvim_win_get_config, win)
				if ok and config and config.relative ~= "" then
					local width = config.width or 0
					local height = config.height or 0
					local title = config.title
					if (not title) and (width <= 80 and height <= 40) and vim.api.nvim_win_is_valid(win) then
						pcall(vim.api.nvim_win_close, win, true)
					end
				end
			end
		end
	end

	-- Autocmd for WinScrolled to close small hover popups on scroll
	vim.api.nvim_create_autocmd("WinScrolled", {
		callback = close_hover_or_small_float_windows,
	})
end

return M
