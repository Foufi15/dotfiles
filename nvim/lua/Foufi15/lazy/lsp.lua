return {
	-- LE CHEF D'ORCHESTRE : NVIM-LSPCONFIG
	"neovim/nvim-lspconfig",

	dependencies = {
		-- 1. GESTION DES OUTILS
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"whoissethdaniel/mason-tool-installer.nvim",

		-- 2. FORMATAGE
		"stevearc/conform.nvim",

		-- 3. AUTOCOMPLÉTION
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",

		-- 4. SNIPPETS
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",

		-- 5. ESTHÉTIQUE
		"j-hui/fidget.nvim",
		"windwp/nvim-autopairs",

		-- 6. TELESCOPE (On en a besoin pour les liens)
		"nvim-telescope/telescope.nvim",
	},

	config = function()
		-- ====================================================================
		-- ÉTAPE 1 : CONFIGURATION DES CAPACITÉS (AUTOCOMPLÉTION)
		-- ====================================================================
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- ====================================================================
		-- ÉTAPE 2 : INSTALLATION AUTOMATIQUE (MASON & TOOLS)
		-- ====================================================================
		require("mason").setup()

		-- Outils sans binaire Mason pour la plateforme : installés par le
		-- gestionnaire de paquets du système (voir install.sh)
		local uname = vim.uv.os_uname()
		local system_only = {}
		if vim.uv.fs_stat("/etc/alpine-release") then -- Alpine (musl)
			system_only = { lua_ls = true, clangd = true, ruff = true, stylua = true }
		elseif uname.sysname == "Linux" and uname.machine == "aarch64" then
			system_only = { clangd = true }
		end

		local function without_system_only(list)
			return vim.tbl_filter(function(name)
				return not system_only[name]
			end, list)
		end

		require("mason-tool-installer").setup({
			ensure_installed = without_system_only({
				"prettier", -- Web
				"stylua", -- Lua
				"ruff", -- Python
				"clang-format", -- C/C++
			}),
		})

		-- Neovim 0.11+ / mason-lspconfig v2 : l'option `handlers` n'existe plus.
		-- On configure les serveurs avec vim.lsp.config, puis mason-lspconfig
		-- les active automatiquement (automatic_enable).
		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		vim.lsp.config("ruff", {
			on_attach = function(client)
				client.server_capabilities.hoverProvider = false
			end,
		})

		vim.lsp.config("pyright", {
			settings = {
				python = {
					analysis = {
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
					},
				},
			},
		})

		vim.lsp.config("lua_ls", {
			settings = { Lua = { diagnostics = { globals = { "vim" } } } },
		})

		vim.lsp.config("clangd", {
			cmd = { "clangd", "--offset-encoding=utf-16" },
		})

		require("mason-lspconfig").setup({
			ensure_installed = without_system_only({
				"lua_ls",
				"ts_ls",
				"html",
				"cssls",
				"tailwindcss",
				"pyright",
				"ruff",
				"clangd",
			}),
			-- rust_analyzer est géré par rustaceanvim
			automatic_enable = { exclude = { "rust_analyzer" } },
		})

		-- Serveurs installés par le système (hors Mason) : on les active nous-mêmes
		for server in pairs(system_only) do
			local cmd = vim.lsp.config[server] and vim.lsp.config[server].cmd
			if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
				vim.lsp.enable(server)
			end
		end

		-- ====================================================================
		-- ÉTAPE 3 : FORMATAGE (CONFORM)
		-- ====================================================================
		require("conform").setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				markdown = { "prettier" },
				lua = { "stylua" },
				c = { "clang-format" },
				rust = { "rustfmt" },
				cpp = { "clang-format" },
				python = { "ruff_organize_imports", "ruff_format" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		})

		-- ====================================================================
		-- ÉTAPE 4 : MOTEUR D'AUTOCOMPLÉTION (CMP)
		-- ====================================================================
		local cmp = require("cmp")
		local luasnip = require("luasnip")

		require("luasnip.loaders.from_vscode").lazy_load()
		require("fidget").setup({})

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			mapping = cmp.mapping.preset.insert({
				["<C-k>"] = cmp.mapping.select_prev_item(),
				["<C-j>"] = cmp.mapping.select_next_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					elseif luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif luasnip.jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
			}, {
				{ name = "buffer" },
			}),
		})

		-- (L'intégration nvim-autopairs ↔ cmp est faite dans autopairs.lua)

		-- ====================================================================
		-- ÉTAPE 5 : GESTION DES ERREURS & RACCOURCIS
		-- ====================================================================

		vim.diagnostic.config({
			virtual_text = {
				prefix = "●",
				spacing = 4,
			},
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "✘",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.HINT] = "⚑",
					[vim.diagnostic.severity.INFO] = "",
				},
			},
			float = {
				border = "rounded",
				source = true,
			},
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Voir l'erreur (Bulle)" })
		vim.keymap.set("n", "[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, { desc = "Erreur précédente" })
		vim.keymap.set("n", "]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, { desc = "Erreur suivante" })
		vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Liste des erreurs" })

		-- ====================================================================
		-- ÉTAPE 6 : NAVIGATION INTELLIGENTE (AVEC TELESCOPE)
		-- ====================================================================

		-- On charge Telescope
		local telescope_builtin = require("telescope.builtin")

		-- K : Voir la doc (Reste natif, c'est mieux pour la doc)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Voir la documentation" })

		-- gd : Go Definition (Si plusieurs définitions, ouvre Telescope)
		vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, { desc = "Aller à la définition" })

		-- gr : Go References (Affiche toutes les fois où la fonction est utilisée dans Telescope)
		vim.keymap.set("n", "gr", telescope_builtin.lsp_references, { desc = "Voir les références" })

		-- gi : Go Implementation (Pour le C++/Java)
		vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, { desc = "Aller à l'implémentation" })

		-- <leader>ds : Document Symbols (Liste toutes les fonctions du fichier actuel)
		vim.keymap.set("n", "<leader>ds", telescope_builtin.lsp_document_symbols, { desc = "Symboles du document" })

		-- Renommage et Actions (Restent natifs)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Renommer intelligemment" })
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Actions de code" })

		-- Inlay Hints
		vim.keymap.set("n", "<leader>h", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
		end, { desc = "Toggle Inlay Hints" })
	end,
}
