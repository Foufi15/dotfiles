return {
	{
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000, -- Très important : force le thème à se charger avant les autres plugins
	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- Options disponibles : latte (clair), frappe, macchiato, mocha (le plus sombre)
			background = {
				light = "latte",
				dark = "mocha",
			},
			transparent_background = false, -- Laisser à false : Foufi15/theme.lua recopie le fond du thème dans Ghostty
			show_end_of_buffer = false,
			term_colors = true,
			dim_inactive = {
				enabled = false, -- Assombrit les fenêtres inactives (pratique avec les splits)
				shade = "dark",
				percentage = 0.15,
			},
			no_italic = false,
			no_bold = false,
			no_underline = false,
			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
				loops = {},
				functions = {},
				keywords = {},
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
				operators = {},
			},
			color_overrides = {},
			custom_highlights = {},

			-- C'est ici que la magie opère : on active le support pour tes autres plugins
			integrations = {
				cmp = true,
				gitsigns = true,
				nvimtree = false,
				treesitter = true,
				notify = false,
				mini = {
					enabled = true,
					indentscope_color = "",
				},
				telescope = {
					enabled = true,
				},
				indent_blankline = {
					enabled = true,
					scope_color = "",
					colored_indent_levels = false,
				},
				neotree = true,
				illuminate = true,
				render_markdown = true,
			},
		})
	end,
	},

	-- Autres thèmes dispo : <leader>ft pour choisir (le choix est mémorisé, voir Foufi15/theme.lua)
	-- Pas de fond transparent : theme.lua a besoin de la couleur de fond pour l'envoyer à Ghostty
	{ "folke/tokyonight.nvim", priority = 1000 },
	{ "rebelot/kanagawa.nvim", priority = 1000 },
	{ "rose-pine/neovim", name = "rose-pine", priority = 1000 },
	{ "ellisonleao/gruvbox.nvim", priority = 1000 },
	{ "navarasu/onedark.nvim", priority = 1000 },
	{ "neanias/everforest-nvim", main = "everforest", priority = 1000, opts = {} },
	{ "gbprod/nord.nvim", priority = 1000 },
}
