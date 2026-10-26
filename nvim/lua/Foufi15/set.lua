vim.opt.clipboard = "unnamedplus" -- use system keyboard for yank

vim.opt.nu = true -- set line numbers -- set line numbers
vim.opt.relativenumber = true -- use relative line numbers

-- set tab size to 4 spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.incsearch = true -- incremental search

vim.opt.termguicolors = true

-- ==============================================================================
-- Auto-rechargement des fichiers modifiés en externe (ex: par Claude Code)
-- ==============================================================================

-- 1. Activer le rechargement automatique au niveau de Neovim
vim.o.autoread = true

-- 2. Créer un groupe d'autocommandes pour garder les choses propres
local autoread_group = vim.api.nvim_create_augroup("AutoReadExternalChanges", { clear = true })

-- 3. Forcer la vérification du fichier lors d'un changement d'état
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = autoread_group,
	pattern = "*",
	command = "if mode() != 'c' | checktime | endif",
})

-- (Optionnel) Raccourcir le temps de déclenchement de CursorHold (par défaut 4000ms)
-- Cela rendra la détection plus réactive si tu restes sur le panneau Neovim sans bouger.
vim.o.updatetime = 300
