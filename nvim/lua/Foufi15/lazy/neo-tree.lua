return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			-- Option globale importante
			close_if_last_window = true,

			filesystem = {
				-- IMPORTANT : Ne pas fermer l'arbre quand on ouvre un fichier
				bind_to_cwd = false,
				follow_current_file = { enabled = true },

				-- LA CONFIGURATION DE LA TOUCHE
				window = {
					mappings = {
						-- Touche 'o' pour ouvrir sans quitter
						["o"] = "open_and_stay",
						-- Touche 'Entrée' classique (ouvre et quitte l'arbre)
						["<cr>"] = "open",
					},
				},

				-- LA COMMANDE PERSONNALISÉE (CORRIGÉE)
				commands = {
					open_and_stay = function(state)
						local node = state.tree:get_node()
						if node.type == "file" then
							-- 1. On lance l'ouverture du fichier normalement
							require("neo-tree.sources.filesystem.commands").open(state)

							-- 2. On utilise 'schedule' pour attendre que l'ouverture soit finie
							-- avant de reprendre le focus brutalement
							vim.schedule(function()
								vim.cmd("Neotree focus")
							end)
						elseif node.type == "directory" then
							-- Si c'est un dossier, on l'ouvre/ferme simplement
							require("neo-tree.sources.filesystem.commands").toggle_node(state)
						end
					end,
				},
			},
		})
	end,
}
