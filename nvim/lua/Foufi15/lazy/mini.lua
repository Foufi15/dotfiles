return {
	"echasnovski/mini.nvim",
	version = false, -- Utilisez la version main pour les dernières fonctionnalités
	config = function()
		-- Exemple 2 : Surround (ajoute/modifie les guillemets autour d'un mot)
		-- 'saiw"' ajoute des guillemets autour du mot
		require("mini.surround").setup()

		-- Exemple 3 : Comment (pour commenter des lignes avec 'gc')
		require("mini.comment").setup()
	end,
}
