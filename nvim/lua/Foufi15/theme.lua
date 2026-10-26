-- Mémorise le dernier thème choisi (via :colorscheme ou <leader>ft) et le réapplique au démarrage.
-- Synchronise aussi le fond de Ghostty et les couleurs de neo-tree avec le thème.
local file = vim.fn.stdpath("data") .. "/colorscheme.txt"
local default = "catppuccin"

-- Envoie une séquence au terminal (enveloppée pour traverser tmux, qui a allow-passthrough on)
local function send(seq)
	if vim.env.TMUX then
		seq = "\027Ptmux;" .. seq:gsub("\027", "\027\027") .. "\027\\"
	end
	vim.api.nvim_ui_send(seq)
end

-- Fichier inclus par la config Ghostty (config-file = ?nvim-theme) : les nouvelles
-- fenêtres Ghostty démarrent avec le fond du dernier thème choisi
local ghostty_file = vim.fn.expand("~/Library/Application Support/com.mitchellh.ghostty/nvim-theme")

-- Donne à Ghostty la couleur de fond du thème (OSC 11). Le fond reste après avoir quitté nvim.
local function sync_bg()
	local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
	if not bg then
		return
	end
	send(string.format("\027]11;#%06x\007", bg))
	local out = io.open(ghostty_file, "w")
	if out then
		out:write(string.format("background = #%06x\n", bg))
		out:close()
	end
end

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function(args)
		require("Foufi15.chrome").apply_neotree()
		sync_bg()
		local out = io.open(file, "w")
		if out then
			out:write(args.match)
			out:close()
		end
	end,
})

vim.api.nvim_create_autocmd({ "UIEnter", "VimResume" }, { callback = sync_bg })

local f = io.open(file, "r")
local saved = f and f:read("*l") or default
if f then f:close() end

if not pcall(vim.cmd.colorscheme, saved) then
	vim.cmd.colorscheme(default)
end
