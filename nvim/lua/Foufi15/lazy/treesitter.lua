-- nvim-treesitter branche "main" : plus de `nvim-treesitter.configs`.
-- On installe les parsers et on active highlight/indent nous-mêmes via un autocmd FileType.
local ensure_installed = {
	"c",
	"lua",
	"vim",
	"vimdoc",
	"python",
	"markdown",
	"markdown_inline",
	"javascript",
	"typescript",
	"html",
	"css",
	"bash",
	"java",
	"rust",
}

local max_filesize = 100 * 1024 -- 100 KB

local function enable_treesitter(buf, lang)
	local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
	if ok and stats and stats.size > max_filesize then
		return
	end
	if not pcall(vim.treesitter.start, buf, lang) then
		return
	end
	vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		lazy = false, -- la branche main ne supporte pas le lazy-loading
		config = function()
			local ts = require("nvim-treesitter")
			ts.install(ensure_installed)

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(args.match)
					if not lang then
						return
					end

					if vim.list_contains(ts.get_installed(), lang) then
						enable_treesitter(args.buf, lang)
					elseif vim.list_contains(ts.get_available(), lang) then
						-- équivalent de l'ancien `auto_install = true`
						ts.install(lang):await(function()
							vim.schedule(function()
								if vim.api.nvim_buf_is_valid(args.buf) then
									enable_treesitter(args.buf, lang)
								end
							end)
						end)
					end
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup({
				enable = true,
				mode = "cursor",
				max_lines = 0,
				separator = "—",
				on_attach = function(buf)
					return true
				end,
			})
		end,
	},
}
