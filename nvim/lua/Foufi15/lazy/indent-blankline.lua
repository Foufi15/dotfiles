return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",

	-- On utilise config pour déclarer les highlight groups et les hooks
	config = function()
		local highlight =
			{
				"RainbowYellow",
			}, 
require("ibl").setup({

				indent = { highlight = highlight },

				scope = {
					highlight = highlight,
					enabled = true, -- Laisse le scope actif (couleur changeante)
					show_start = false, -- ENLÈVE la barre horizontale du haut
					show_end = false, -- ENLÈVE la barre horizontale du bas
					show_exact_scope = false, -- Enlève le soulignement du nom de la fonction
				},
			})
	end,
}
