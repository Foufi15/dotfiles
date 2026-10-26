return {
	"christoomey/vim-tmux-navigator",
	cmd = {
		"TmuxNavigateLeft",
		"TmuxNavigateDown",
		"TmuxNavigateUp",
		"TmuxNavigateRight",
		"TmuxNavigatePrevious",
	},
	keys = {
		{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Aller à gauche" },
		{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Aller en bas" },
		{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Aller en haut" },
		{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Aller à droite" },
		{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Fenêtre précédente" },
	},
}
