# dotfiles

Ma config terminal, pour macOS et Linux : **zsh** (Oh My Zsh), **Neovim**, **tmux**, **yazi**, **git**, **btop**, **fastfetch** et **AeroSpace** (macOS).

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Foufi15/dotfiles/main/install.sh | bash
```

Ou depuis un clone :

```bash
git clone https://github.com/Foufi15/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Le script :

1. installe les paquets (Homebrew sur macOS ; apt, dnf/yum, pacman, zypper ou apk sur Linux). yazi, zoxide et fastfetch sont téléchargés depuis GitHub si la distribution ne les fournit pas ;
2. installe Oh My Zsh, `zsh-autosuggestions`, `zsh-syntax-highlighting` et tpm ;
3. crée les liens symboliques (tout fichier existant est sauvegardé en `*.bak.<date>`) ;
4. installe les plugins tmux, puis lance [`nvim/install.sh`](nvim/README.md) (Neovim ≥ 0.11, LSP, treesitter, Nerd Font…) ;
5. met zsh comme shell par défaut.

On peut le relancer sans risque : les liens déjà en place ne sont pas touchés.

### Options

| Option | Effet |
|---|---|
| `--link-only` | Crée seulement les liens, n'installe rien |
| `--no-nvim` | Saute l'installation des dépendances Neovim |
| `--yes` | Aucune question |
| `--no-font`, `--no-rust`, `--skip-plugins`, `--font NOM` | Transmises à `nvim/install.sh` |

## Contenu

| Dossier | Lien créé |
|---|---|
| `zsh/.zshrc`, `.zshenv`, `.zprofile` | `~/` |
| `git/gitconfig`, `git/ignore` | `~/.gitconfig`, `~/.config/git/ignore` |
| `nvim/` | `~/.config/nvim` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `yazi/` | `~/.config/yazi` |
| `btop/btop.conf` | `~/.config/btop/btop.conf` |
| `fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` |
| `macos/aerospace/aerospace.toml` | `~/.config/aerospace/aerospace.toml` (macOS seulement) |

Comme ce sont des liens, modifier `~/.zshrc` ou `~/.config/nvim` modifie directement le dépôt : il suffit ensuite de `git commit` et `git push`.

Les réglages propres à une machine (chemins, tokens…) vont dans `~/.zshrc.local`, qui n'est pas versionné.

## Raccourcis utiles

- **tmux** : préfixe `Ctrl+d`, `Ctrl+h/j/k/l` pour changer de split (partagé avec Neovim), `préfixe + t` pour un terminal flottant, `préfixe + r` pour recharger. La copie va dans le presse-papiers système (pbcopy, wl-copy ou xclip).
- **yazi** : `y` ouvre yazi et change de dossier en quittant ; `Entrée` ouvre le fichier dans nvim (nouvelle fenêtre tmux), `o` dans une popup tmux.
