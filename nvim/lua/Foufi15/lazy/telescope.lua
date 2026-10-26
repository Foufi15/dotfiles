return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8", -- On utilise une version stable
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- Pour les jolies icônes
		-- (Optionnel) FZF permet de rendre la recherche ultra rapide (nécessite 'make')
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},

	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				-- Raccourcis DANS la fenêtre Telescope
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- Monter avec Ctrl+k
						["<C-j>"] = actions.move_selection_next, -- Descendre avec Ctrl+j
						["<Esc>"] = actions.close, -- Quitter avec Echap direct
					},
				},
				-- Apparence
				layout_strategy = "horizontal",
				layout_config = {
					preview_width = 0.55,
				},
				-- Fichiers à ignorer
				file_ignore_patterns = { "node_modules", ".git", "target", "build" },
			},
		})

		-- Charger l'extension FZF pour la vitesse (si installée)
		pcall(telescope.load_extension, "fzf")

		-- ==========================================================
		-- LES RACCOURCIS CLAVIERS (C'est ça le plus important)
		-- ==========================================================
		local builtin = require("telescope.builtin")

		-- <leader>ff = Find Files (Trouver un fichier par son nom)
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope : Fichiers" })

		-- <leader>fg = Find Grep (Chercher du texte DANS les fichiers)
		-- Nécessite 'ripgrep' installé sur ton Mac (brew install ripgrep)
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope : Texte" })

		-- <leader>fb = Find Buffers (Voir les onglets ouverts)
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope : Buffers" })

		-- <leader>fh = Find Help (Chercher dans l'aide de Neovim)
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope : Aide" })

		-- <leader>ft = Find Theme (Changer de thème avec aperçu en direct)
		vim.keymap.set("n", "<leader>ft", function()
			builtin.colorscheme({ enable_preview = true })
		end, { desc = "Telescope : Thème" })
	end,
}
