# Config Neovim

Configuration Neovim basée sur [lazy.nvim](https://github.com/folke/lazy.nvim) : LSP (Mason), autocomplétion (nvim-cmp), Telescope, Neo-tree, Treesitter, Rust (rustaceanvim), thème Catppuccin.

## Installation

Une seule commande, sur macOS ou Linux (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine) :

```bash
curl -fsSL https://raw.githubusercontent.com/Foufi15/nvim/main/install.sh | bash
```

Le script installe toutes les dépendances (Neovim ≥ 0.11, git, compilateur C, ripgrep, fd, Node.js, Python, Rust, tree-sitter CLI, Nerd Font…), clone la config dans `~/.config/nvim` (l'ancienne est sauvegardée en `nvim.bak.<date>`), puis installe les plugins, les LSP et les parsers.

> **Alpine** : `bash` et `curl` ne sont pas installés par défaut, lance d'abord `apk add bash curl`.

Pour passer des options avec `curl | bash` :

```bash
curl -fsSL https://raw.githubusercontent.com/Foufi15/nvim/main/install.sh | bash -s -- --no-font
```

Ou depuis un clone local :

```bash
git clone https://github.com/Foufi15/nvim.git ~/.config/nvim
~/.config/nvim/install.sh
```

### Options

| Option | Effet |
|---|---|
| `--no-font` | N'installe pas la Nerd Font |
| `--no-rust` | N'installe pas rustup / rust-analyzer |
| `--skip-plugins` | N'installe pas les plugins, LSP et parsers dans Neovim |
| `--help` | Affiche l'aide |

### Après l'installation

1. Ouvre un nouveau terminal.
2. Choisis la police **JetBrainsMono Nerd Font** dans ton terminal (sinon les icônes s'affichent mal).
3. Lance `nvim`, puis `:checkhealth` pour vérifier.
