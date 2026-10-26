return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern", -- Fenêtre flottante centrée en bas ("classic" ou "helix" possibles aussi)
		delay = 300, -- Délai (ms) avant que le popup apparaisse après avoir tapé <leader>

		-- Noms des groupes (les préfixes qui ouvrent un sous-menu)
		spec = {
			{ "<leader>f", group = "Telescope (Chercher)" },
			{ "<leader>d", group = "Document" },
			{ "<leader>r", group = "Renommer" },
			{ "<leader>c", group = "Code" },
			{ "g", group = "Aller à (LSP)" },
			{ "[", group = "Précédent" },
			{ "]", group = "Suivant" },

			-- mini.comment
			{ "gc", group = "Commenter", mode = { "n", "x" } },
			{ "gcc", desc = "Commenter la ligne" },

			-- mini.surround (entourer un mot avec des guillemets, parenthèses...)
			{ "s", group = "Surround (entourer)", mode = { "n", "x" } },
			{ "sa", desc = "Ajouter autour (ex: saiw\")", mode = { "n", "x" } },
			{ "sd", desc = "Supprimer autour (ex: sd\")" },
			{ "sr", desc = "Remplacer autour (ex: sr\"')" },
			{ "sf", desc = "Trouver à droite" },
			{ "sF", desc = "Trouver à gauche" },
			{ "sh", desc = "Surligner" },
			{ "sn", desc = "Changer le nb de lignes de recherche" },
		},
	},
	keys = {
		-- <leader>? : Affiche TOUS les raccourcis disponibles dans le buffer actuel
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Raccourcis du buffer",
		},
	},
}
