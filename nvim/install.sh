#!/usr/bin/env bash
# ==============================================================================
# install.sh — Installe toutes les dépendances de cette config Neovim
#
# Supporte : macOS (Intel / Apple Silicon) et Linux (x86_64 / arm64)
#            apt (Debian/Ubuntu/Mint/Pop), dnf/yum (Fedora/RHEL/Rocky/Alma),
#            pacman (Arch/Manjaro/EndeavourOS), zypper (openSUSE), apk (Alpine)
#
# Usage :
#   ./install.sh                  # installation complète
#   ./install.sh --font FiraCode  # choisit la Nerd Font (sinon : menu interactif)
#   ./install.sh --no-font        # sans la Nerd Font
#   ./install.sh --yes            # aucune question (police par défaut : JetBrainsMono)
#   ./install.sh --no-rust        # sans rustup / rust-analyzer
#   ./install.sh --skip-plugins   # n'installe pas les plugins/LSP dans Neovim
#   curl -fsSL https://raw.githubusercontent.com/Foufi15/nvim/main/install.sh | bash
# ==============================================================================

set -euo pipefail

REPO_URL="https://github.com/Foufi15/nvim.git"
NVIM_MIN_VERSION="0.11.0"
NODE_MIN_MAJOR=18
NODE_LTS_CHANNEL="latest-v24.x"
NERD_FONT=""                  # vide → menu interactif (défaut : JetBrainsMono)
NERD_FONT_DEFAULT="JetBrainsMono"
NERD_FONTS="JetBrainsMono FiraCode Hack Meslo CascadiaCode Iosevka SourceCodePro UbuntuMono"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"

INSTALL_FONT=1
INSTALL_RUST=1
INSTALL_PLUGINS=1
ASSUME_YES=0

# ------------------------------------------------------------------------------
# Affichage
# ------------------------------------------------------------------------------
if [ -t 1 ]; then
	C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
	C_RED=$'\033[1;31m'; C_RESET=$'\033[0m'
else
	C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_RESET=""
fi

step() { printf '\n%s==> %s%s\n' "$C_BLUE" "$*" "$C_RESET"; }
ok()   { printf '%s  ✔ %s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf '%s  ! %s%s\n' "$C_YELLOW" "$*" "$C_RESET"; }
die()  { printf '%s  ✘ %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; exit 1; }

usage() {
	sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
	echo "Polices disponibles : $NERD_FONTS"
	exit 0
}

while [ $# -gt 0 ]; do
	case "$1" in
		--font) [ $# -ge 2 ] || die "--font attend un nom de police"; NERD_FONT="$2"; shift ;;
		--font=*) NERD_FONT="${1#--font=}" ;;
		--no-font) INSTALL_FONT=0 ;;
		--no-rust) INSTALL_RUST=0 ;;
		--skip-plugins) INSTALL_PLUGINS=0 ;;
		-y|--yes) ASSUME_YES=1 ;;
		-h|--help) usage ;;
		*) die "Option inconnue : $1 (voir --help)" ;;
	esac
	shift
done

# ------------------------------------------------------------------------------
# Utilitaires
# ------------------------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

# version_ge A B  → vrai si A >= B (compatible bash 3.2 / macOS)
version_ge() {
	local IFS=.
	local -a a b
	read -r -a a <<<"${1%%-*}"
	read -r -a b <<<"${2%%-*}"
	local i
	for i in 0 1 2; do
		local x="${a[$i]:-0}" y="${b[$i]:-0}"
		x="${x//[^0-9]/}"; y="${y//[^0-9]/}"
		x="${x:-0}"; y="${y:-0}"
		if [ "$x" -gt "$y" ]; then return 0; fi
		if [ "$x" -lt "$y" ]; then return 1; fi
	done
	return 0
}

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	if has sudo; then
		SUDO="sudo"
	elif has doas; then
		SUDO="doas"
	fi
fi

as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	elif [ -n "$SUDO" ]; then
		$SUDO "$@"
	else
		die "Droits administrateur requis pour : $* (installe sudo ou lance en root)"
	fi
}

download() { # download URL DEST (3 tentatives, pour les coupures réseau)
	local attempt
	for attempt in 1 2 3; do
		if has curl; then
			curl -fsSL --retry 3 -o "$2" "$1" && return 0
		elif has wget; then
			wget -qO "$2" "$1" && return 0
		else
			die "Ni curl ni wget n'est disponible."
		fi
		warn "Échec du téléchargement de $1 (tentative $attempt/3)"
		sleep 2
	done
	return 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$LOCAL_BIN" "$LOCAL_OPT"
export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$PATH"

# ------------------------------------------------------------------------------
# Détection du système
# ------------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$ARCH" in
	x86_64|amd64) ARCH="x86_64" ;;
	aarch64|arm64) ARCH="arm64" ;;
	*) die "Architecture non supportée : $ARCH" ;;
esac

PM=""
case "$OS" in
	Darwin) PM="brew" ;;
	Linux)
		if has apt-get; then PM="apt"
		elif has dnf; then PM="dnf"
		elif has yum; then PM="yum"
		elif has pacman; then PM="pacman"
		elif has zypper; then PM="zypper"
		elif has apk; then PM="apk"
		else die "Gestionnaire de paquets non supporté (apt, dnf, yum, pacman, zypper, apk)."
		fi
		;;
	*) die "Système non supporté : $OS" ;;
esac

step "Système détecté : $OS / $ARCH / $PM"

# ------------------------------------------------------------------------------
# 1. Paquets système
# ------------------------------------------------------------------------------
install_homebrew() {
	if has brew; then return; fi
	step "Installation de Homebrew"
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if [ -x /opt/homebrew/bin/brew ]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [ -x /usr/local/bin/brew ]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi
	has brew || die "Homebrew n'a pas pu être installé."
}

install_system_packages() {
	step "Installation des paquets système"
	case "$PM" in
		brew)
			xcode-select -p >/dev/null 2>&1 || {
				warn "Outils de ligne de commande Xcode absents : lancement de l'installation…"
				xcode-select --install || true
				warn "Termine l'installation Xcode puis relance ce script."
				exit 1
			}
			install_homebrew
			brew update
			brew install git curl wget unzip ripgrep fd node python tmux neovim
			brew install tree-sitter-cli 2>/dev/null || true
			;;
		apt)
			as_root apt-get update
			as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
				git curl wget unzip tar gzip xz-utils build-essential ripgrep fd-find \
				python3 python3-pip python3-venv nodejs npm xclip wl-clipboard tmux \
				fontconfig ca-certificates
			# Debian/Ubuntu nomment le binaire "fdfind"
			if ! has fd && has fdfind; then ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"; fi
			;;
		dnf|yum)
			as_root "$PM" install -y \
				git curl wget unzip tar gzip xz gcc gcc-c++ make ripgrep fd-find \
				python3 python3-pip nodejs npm xclip wl-clipboard tmux fontconfig \
				|| { warn "Certains paquets manquent, activation d'EPEL puis nouvel essai…"
				     as_root "$PM" install -y epel-release || true
				     as_root "$PM" install -y git curl wget unzip tar gzip xz gcc gcc-c++ make \
				         ripgrep fd-find python3 python3-pip nodejs npm xclip tmux fontconfig; }
			;;
		pacman)
			as_root pacman -Syu --needed --noconfirm \
				git curl wget unzip tar gzip xz base-devel ripgrep fd python python-pip \
				nodejs npm xclip wl-clipboard tmux fontconfig neovim tree-sitter-cli
			;;
		zypper)
			as_root zypper --non-interactive refresh
			as_root zypper --non-interactive install -y \
				git curl wget unzip tar gzip xz gcc gcc-c++ make ripgrep fd \
				python3 python3-pip nodejs npm xclip wl-clipboard tmux fontconfig
			;;
		apk)
			as_root apk update
			as_root apk add \
				bash git curl wget unzip tar gzip xz build-base ripgrep fd python3 py3-pip \
				nodejs npm xclip wl-clipboard tmux fontconfig neovim tree-sitter-cli \
				lua-language-server clang-extra-tools stylua ruff # pas de binaires Mason pour musl
			;;
	esac
	# Mason n'a pas de clangd pour Linux ARM64 → paquet du système
	if [ "$OS" = "Linux" ] && [ "$ARCH" = "arm64" ]; then
		case "$PM" in
			apt) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y clangd ;;
			dnf|yum) as_root "$PM" install -y clang-tools-extra ;;
			pacman) as_root pacman -S --needed --noconfirm clang ;;
			zypper) as_root zypper --non-interactive install -y clang-tools ;;
		esac
	fi
	ok "Paquets système installés"
}

# ------------------------------------------------------------------------------
# 2. Neovim (>= NVIM_MIN_VERSION, les dépôts Linux sont souvent trop vieux)
# ------------------------------------------------------------------------------
nvim_version() { nvim --version 2>/dev/null | head -n1 | sed -E 's/^NVIM v?//'; }

install_neovim() {
	step "Neovim (>= $NVIM_MIN_VERSION)"
	if has nvim && version_ge "$(nvim_version)" "$NVIM_MIN_VERSION"; then
		ok "Neovim $(nvim_version) déjà présent"
		return
	fi

	if [ "$PM" = "brew" ]; then
		brew install neovim || brew upgrade neovim
	elif [ "$PM" = "apk" ]; then
		# Alpine (musl) : les binaires officiels sont glibc, on reste sur apk
		as_root apk add --upgrade neovim
	else
		local asset="nvim-linux-${ARCH}"
		download "https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz" \
			"$TMP_DIR/nvim.tar.gz"
		rm -rf "$LOCAL_OPT/$asset"
		tar -xzf "$TMP_DIR/nvim.tar.gz" -C "$LOCAL_OPT"
		ln -sf "$LOCAL_OPT/$asset/bin/nvim" "$LOCAL_BIN/nvim"
		hash -r
	fi

	has nvim && version_ge "$(nvim_version)" "$NVIM_MIN_VERSION" \
		|| die "Impossible d'installer Neovim >= $NVIM_MIN_VERSION"
	ok "Neovim $(nvim_version) installé"
}

# ------------------------------------------------------------------------------
# 3. Node.js (LSP web : ts_ls, html, cssls, tailwindcss, pyright, prettier)
# ------------------------------------------------------------------------------
install_node() {
	step "Node.js (>= $NODE_MIN_MAJOR)"
	local major=0
	if has node; then major="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"; fi
	if [ "$major" -ge "$NODE_MIN_MAJOR" ]; then
		ok "Node $(node -v) déjà présent"
		return
	fi
	if [ "$PM" = "brew" ]; then
		brew install node
	else
		local plat="linux-x64"
		[ "$ARCH" = "arm64" ] && plat="linux-arm64"
		local base="https://nodejs.org/dist/${NODE_LTS_CHANNEL}"
		download "$base/SHASUMS256.txt" "$TMP_DIR/node-sums.txt"
		local file
		file="$(grep -o "node-v[0-9.]*-${plat}\.tar\.xz" "$TMP_DIR/node-sums.txt" | head -n1)"
		[ -n "$file" ] || die "Archive Node.js introuvable pour $plat"
		download "$base/$file" "$TMP_DIR/$file"
		rm -rf "$LOCAL_OPT/node"
		mkdir -p "$LOCAL_OPT/node"
		tar -xJf "$TMP_DIR/$file" -C "$LOCAL_OPT/node" --strip-components=1
		ln -sf "$LOCAL_OPT/node/bin/node" "$LOCAL_BIN/node"
		ln -sf "$LOCAL_OPT/node/bin/npm" "$LOCAL_BIN/npm"
		ln -sf "$LOCAL_OPT/node/bin/npx" "$LOCAL_BIN/npx"
		hash -r
	fi
	ok "Node $(node -v) installé"
}

# ------------------------------------------------------------------------------
# 4. tree-sitter CLI (requis par nvim-treesitter branche "main")
# ------------------------------------------------------------------------------
install_tree_sitter_cli() {
	step "tree-sitter CLI"
	if has tree-sitter; then
		ok "tree-sitter $(tree-sitter --version | awk '{print $2}') déjà présent"
		return
	fi
	local os_name="linux" arch_name="x64"
	[ "$OS" = "Darwin" ] && os_name="macos"
	[ "$ARCH" = "arm64" ] && arch_name="arm64"
	if download "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-${os_name}-${arch_name}.gz" \
		"$TMP_DIR/tree-sitter.gz"; then
		gunzip -f "$TMP_DIR/tree-sitter.gz"
		install -m 755 "$TMP_DIR/tree-sitter" "$LOCAL_BIN/tree-sitter"
	fi
	# Le binaire précompilé peut ne pas tourner (glibc trop ancienne) → cargo
	if ! tree-sitter --version >/dev/null 2>&1; then
		rm -f "$LOCAL_BIN/tree-sitter"
		if has cargo; then
			warn "Binaire précompilé inutilisable, compilation via cargo…"
			cargo install --locked tree-sitter-cli
		else
			warn "tree-sitter CLI non installé (les parsers treesitter ne pourront pas être compilés)"
			return
		fi
	fi
	ok "tree-sitter installé"
}

# ------------------------------------------------------------------------------
# 5. Rust (rustaceanvim : rust-analyzer, rustfmt, clippy)
# ------------------------------------------------------------------------------
install_rust() {
	step "Rust toolchain"
	if ! has rustup; then
		curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
		# shellcheck disable=SC1091
		. "$HOME/.cargo/env"
	fi
	rustup toolchain install stable --profile minimal >/dev/null
	rustup default stable >/dev/null
	rustup component add rust-analyzer rustfmt clippy rust-src
	ok "$(rustc --version) + rust-analyzer installés"
}

# ------------------------------------------------------------------------------
# 6. Nerd Font (icônes neo-tree, bufferline, devicons)
# ------------------------------------------------------------------------------
# font_info NOM → FONT_CASK (Homebrew) et FONT_LABEL (nom à choisir dans le terminal)
font_info() {
	case "$1" in
		JetBrainsMono) FONT_CASK="font-jetbrains-mono-nerd-font"; FONT_LABEL="JetBrainsMono Nerd Font" ;;
		FiraCode) FONT_CASK="font-fira-code-nerd-font"; FONT_LABEL="FiraCode Nerd Font" ;;
		Hack) FONT_CASK="font-hack-nerd-font"; FONT_LABEL="Hack Nerd Font" ;;
		Meslo) FONT_CASK="font-meslo-lg-nerd-font"; FONT_LABEL="MesloLGS Nerd Font" ;;
		CascadiaCode) FONT_CASK="font-caskaydia-cove-nerd-font"; FONT_LABEL="CaskaydiaCove Nerd Font" ;;
		Iosevka) FONT_CASK="font-iosevka-nerd-font"; FONT_LABEL="Iosevka Nerd Font" ;;
		SourceCodePro) FONT_CASK="font-sauce-code-pro-nerd-font"; FONT_LABEL="SauceCodePro Nerd Font" ;;
		UbuntuMono) FONT_CASK="font-ubuntu-mono-nerd-font"; FONT_LABEL="UbuntuMono Nerd Font" ;;
		*) return 1 ;;
	esac
}

# Menu de choix de la police (lit /dev/tty pour marcher aussi avec curl | bash)
choose_font() {
	if [ -n "$NERD_FONT" ]; then
		font_info "$NERD_FONT" || die "Police inconnue : $NERD_FONT (choix : $NERD_FONTS)"
		return
	fi
	NERD_FONT="$NERD_FONT_DEFAULT"
	if [ "$ASSUME_YES" -eq 1 ] || ! { : </dev/tty; } 2>/dev/null; then
		font_info "$NERD_FONT"
		return
	fi

	step "Quelle Nerd Font installer ?"
	local i=1 name
	for name in $NERD_FONTS; do
		font_info "$name"
		printf '  %d) %s\n' "$i" "$FONT_LABEL"
		i=$((i + 1))
	done
	printf '  %d) Aucune\n' "$i"

	local choice
	printf 'Choix [1] : '
	read -r choice </dev/tty || choice=""
	choice="${choice:-1}"
	if [ "$choice" = "$i" ]; then
		INSTALL_FONT=0
		return
	fi
	i=1
	for name in $NERD_FONTS; do
		if [ "$choice" = "$i" ] || [ "$choice" = "$name" ]; then
			NERD_FONT="$name"
			break
		fi
		i=$((i + 1))
	done
	font_info "$NERD_FONT"
	ok "Police choisie : $FONT_LABEL"
}

install_font() {
	step "Nerd Font ($FONT_LABEL)"
	if [ "$OS" = "Darwin" ]; then
		brew install --cask "$FONT_CASK" || return 1
	else
		local dir="$HOME/.local/share/fonts/${NERD_FONT}NerdFont"
		if [ -d "$dir" ] && ls "$dir"/*.ttf >/dev/null 2>&1; then
			ok "Police déjà installée"
			return
		fi
		mkdir -p "$dir"
		download "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT}.tar.xz" \
			"$TMP_DIR/font.tar.xz" || return 1
		tar -xJf "$TMP_DIR/font.tar.xz" -C "$dir" || return 1
		has fc-cache && fc-cache -f "$dir" >/dev/null
	fi
	ok "Police installée → choisis « $FONT_LABEL » dans ton terminal"
}

# ------------------------------------------------------------------------------
# 7. Mise en place de la config dans ~/.config/nvim
# ------------------------------------------------------------------------------
setup_config() {
	step "Configuration Neovim"
	local target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
	local src=""

	# Script lancé depuis le dépôt ? (sinon : curl | bash)
	if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/init.lua" ]; then
		src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	fi

	if [ -n "$src" ] && [ -d "$target" ] && [ "$(cd "$target" && pwd -P)" = "$src" ]; then
		ok "La config est déjà en place ($target)"
		return
	fi

	if [ -e "$target" ] || [ -L "$target" ]; then
		local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
		warn "Config existante sauvegardée dans $backup"
		mv "$target" "$backup"
	fi
	mkdir -p "$(dirname "$target")"

	if [ -n "$src" ]; then
		ln -s "$src" "$target"
		ok "Lien créé : $target → $src"
	else
		git clone "$REPO_URL" "$target"
		ok "Config clonée dans $target"
	fi
}

# ------------------------------------------------------------------------------
# 8. PATH dans les fichiers de config du shell
# ------------------------------------------------------------------------------
setup_path() {
	step "PATH ($LOCAL_BIN)"
	local line='export PATH="$HOME/.local/bin:$PATH"'
	local rc
	for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
		[ -f "$rc" ] || continue
		grep -qs '.local/bin' "$rc" || { printf '\n%s\n' "$line" >>"$rc"; ok "Ajouté à $rc"; }
	done
	if [ -d "$HOME/.config/fish" ] && has fish; then
		fish -c "fish_add_path -U $LOCAL_BIN" 2>/dev/null || true
	fi
}

# ------------------------------------------------------------------------------
# 9. Plugins, LSP, formatters et parsers treesitter
# ------------------------------------------------------------------------------
install_nvim_plugins() {
	step "Plugins Neovim (lazy.nvim)"
	nvim --headless "+Lazy! sync" +qa
	ok "Plugins installés"

	step "LSP & formatters (Mason)"
	# En mode headless, :MasonInstall est bloquant jusqu'à la fin des installations
	local mason_pkgs="typescript-language-server html-lsp css-lsp tailwindcss-language-server \
pyright prettier clang-format"
	# Sur Alpine, lua-language-server/clangd/ruff/stylua viennent d'apk
	[ "$PM" = "apk" ] || mason_pkgs="$mason_pkgs lua-language-server ruff stylua"
	# Sur Linux ARM64, clangd vient du gestionnaire de paquets
	[ "$PM" = "apk" ] || { [ "$OS" = "Linux" ] && [ "$ARCH" = "arm64" ]; } || mason_pkgs="$mason_pkgs clangd"
	nvim --headless -c "MasonInstall $mason_pkgs" -c qa \
		|| warn "Certains outils Mason ont échoué (relance :Mason dans Neovim)"
	ok "Outils Mason installés"

	step "Parsers treesitter"
	nvim --headless -c "lua local ok, ts = pcall(require, 'nvim-treesitter'); \
if ok and ts.install then ts.install({ 'c', 'lua', 'vim', 'vimdoc', 'python', 'markdown', \
'markdown_inline', 'javascript', 'typescript', 'html', 'css', 'bash', 'java', 'rust' }):wait(300000) \
else vim.cmd('TSUpdateSync') end" -c qa \
		|| warn "Installation des parsers incomplète (relance :TSUpdate dans Neovim)"
	ok "Parsers installés"
}

# ------------------------------------------------------------------------------
# Exécution
# ------------------------------------------------------------------------------
[ "$INSTALL_FONT" -eq 1 ] && choose_font # on pose la question avant les longues installations
install_system_packages
install_neovim
install_node
[ "$INSTALL_RUST" -eq 1 ] && install_rust
install_tree_sitter_cli
# La police est facultative : un échec ne doit pas bloquer le reste
if [ "$INSTALL_FONT" -eq 1 ]; then
	install_font || warn "Police non installée (relance plus tard ou installe-la à la main)"
fi
setup_config
setup_path
[ "$INSTALL_PLUGINS" -eq 1 ] && install_nvim_plugins

step "Terminé 🎉"
echo "  • Ouvre un nouveau terminal (ou : source ~/.zshrc / ~/.bashrc)"
echo "  • Lance : nvim   puis :checkhealth pour vérifier"
[ "$INSTALL_FONT" -eq 1 ] && echo "  • Configure ton terminal avec la police « $FONT_LABEL »"
exit 0
