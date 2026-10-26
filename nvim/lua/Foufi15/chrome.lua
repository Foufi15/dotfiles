-- Couleur commune à neo-tree et aux onglets (bufferline), calculée à partir du thème actif
-- pour que les deux restent cohérents quel que soit le thème choisi.
local M = {}

local function hl(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false })
end

-- Assombrit (pct < 0) ou éclaircit (pct > 0) une couleur
function M.shade(color, pct)
	local r, g, b = math.floor(color / 0x10000), math.floor(color / 0x100) % 0x100, color % 0x100
	local function c(x)
		return math.max(0, math.min(255, math.floor(x * (100 + pct) / 100)))
	end
	return c(r) * 0x10000 + c(g) * 0x100 + c(b)
end

-- Fond de la barre latérale : celui prévu par le thème pour neo-tree s'il en a un,
-- sinon le fond du thème légèrement assombri
function M.bg()
	local normal = hl("Normal").bg or 0
	local tree = hl("NeoTreeNormal").bg
	if tree and tree ~= normal then
		return tree
	end
	return M.shade(normal, vim.o.background == "light" and -6 or -18)
end

function M.apply_neotree()
	local bg, fg = M.bg(), hl("Normal").fg
	vim.api.nvim_set_hl(0, "NeoTreeNormal", { fg = fg, bg = bg })
	vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { fg = fg, bg = bg })
	vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { fg = bg, bg = bg })
	vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = bg, bg = bg })
	-- Certains thèmes (nord) affichent les dossiers comme du texte normal
	if hl("NeoTreeDirectoryName").fg == fg then
		vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { link = "Directory" })
		vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { link = "Directory" })
	end
end

-- Pour bufferline : onglets inactifs sur le fond de la barre latérale,
-- fond de la barre un cran plus sombre
function M.bufferline(defaults)
	local h = defaults.highlights
	local map = {
		[h.background.bg] = M.bg(),
		[h.fill.bg] = M.shade(M.bg(), vim.o.background == "light" and -6 or -15),
	}
	local out = {}
	for name, attrs in pairs(h) do
		local bg = attrs.bg and map[attrs.bg]
		if bg then
			out[name] = { bg = string.format("#%06x", bg) }
		end
	end
	return out
end

return M
