#!/usr/bin/env bash
# ==============================================================================
# install.sh — Installe les dotfiles (zsh, nvim, tmux, yazi, git, btop, fastfetch…)
#
# Supporte : macOS (Intel / Apple Silicon) et Linux (x86_64 / arm64)
#            apt, dnf/yum, pacman, zypper, apk
#
# Usage :
#   ./install.sh                 # installation complète
#   ./install.sh --link-only     # crée seulement les liens symboliques
#   ./install.sh --no-nvim       # sans les dépendances / plugins Neovim
#   ./install.sh --yes           # aucune question
#   ./install.sh --no-font       # options transmises à nvim/install.sh :
#   ./install.sh --no-rust       #   --no-font, --no-rust, --skip-plugins,
#   ./install.sh --skip-plugins  #   --font NOM
#   curl -fsSL https://raw.githubusercontent.com/Foufi15/dotfiles/main/install.sh | bash
# ==============================================================================

set -euo pipefail

REPO_URL="https://github.com/Foufi15/dotfiles.git"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
STAMP="$(date +%Y%m%d-%H%M%S)"

LINK_ONLY=0
INSTALL_NVIM=1
NVIM_ARGS=()

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
	exit 0
}

while [ $# -gt 0 ]; do
	case "$1" in
		--link-only) LINK_ONLY=1 ;;
		--no-nvim) INSTALL_NVIM=0 ;;
		-y|--yes|--no-font|--no-rust|--skip-plugins|--font=*) NVIM_ARGS+=("$1") ;;
		--font) [ $# -ge 2 ] || die "--font attend un nom de police"; NVIM_ARGS+=("$1" "$2"); shift ;;
		-h|--help) usage ;;
		*) die "Option inconnue : $1 (voir --help)" ;;
	esac
	shift
done

# ------------------------------------------------------------------------------
# Utilitaires
# ------------------------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	if has sudo; then SUDO="sudo"; elif has doas; then SUDO="doas"; fi
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

download() { # download URL DEST
	if has curl; then
		curl -fsSL --retry 3 -o "$2" "$1"
	elif has wget; then
		wget -qO "$2" "$1"
	else
		die "Ni curl ni wget n'est disponible."
	fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

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

# ------------------------------------------------------------------------------
# 1. Paquets système
# ------------------------------------------------------------------------------
pkg_install() { # installe une liste de paquets, échoue si l'un manque
	case "$PM" in
		brew) brew install "$@" ;;
		apt) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
		dnf|yum) as_root "$PM" install -y "$@" ;;
		pacman) as_root pacman -S --needed --noconfirm "$@" ;;
		zypper) as_root zypper --non-interactive install -y "$@" ;;
		apk) as_root apk add "$@" ;;
	esac
}

pkg_try() { # installe chaque paquet séparément, sans échouer
	local p
	for p in "$@"; do pkg_install "$p" >/dev/null 2>&1 || true; done
}

install_homebrew() {
	has brew && return
	step "Installation de Homebrew"
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if [ -x /opt/homebrew/bin/brew ]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [ -x /usr/local/bin/brew ]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi
	has brew || die "Homebrew n'a pas pu être installé."
}

install_packages() {
	step "Paquets système ($OS / $ARCH / $PM)"
	case "$PM" in
		brew)
			install_homebrew
			brew install git curl wget unzip zsh tmux fzf zoxide btop fastfetch jq \
				yazi ffmpegthumbnailer poppler sevenzip
			brew install --cask nikitabobko/tap/aerospace || warn "AeroSpace non installé"
			;;
		apt)
			as_root apt-get update
			pkg_install git curl wget unzip zsh tmux fzf jq file xclip wl-clipboard ca-certificates
			pkg_try btop zoxide fastfetch ffmpegthumbnailer poppler-utils 7zip
			;;
		dnf|yum)
			pkg_install git curl wget unzip zsh tmux fzf jq file xclip
			pkg_try btop zoxide fastfetch wl-clipboard poppler-utils p7zip
			;;
		pacman)
			as_root pacman -Sy
			pkg_install git curl wget unzip zsh tmux fzf zoxide btop fastfetch jq file \
				xclip wl-clipboard yazi
			pkg_try ffmpegthumbnailer poppler 7zip
			;;
		zypper)
			as_root zypper --non-interactive refresh
			pkg_install git curl wget unzip zsh tmux fzf jq file xclip
			pkg_try btop zoxide fastfetch yazi wl-clipboard poppler-tools 7zip
			;;
		apk)
			as_root apk update
			pkg_install bash git curl wget unzip zsh tmux fzf jq file xclip
			pkg_try btop zoxide fastfetch yazi wl-clipboard poppler-utils 7zip
			;;
	esac
	ok "Paquets système installés"
}

# Outils absents des dépôts de certaines distributions → binaires GitHub
install_zoxide() {
	has zoxide && return
	step "zoxide"
	curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$LOCAL_BIN" \
		&& ok "zoxide installé" || warn "zoxide non installé"
}

install_yazi() {
	has yazi && return
	step "yazi"
	local libc="gnu" arch="x86_64"
	[ "$ARCH" = "arm64" ] && arch="aarch64"
	[ "$PM" = "apk" ] && libc="musl"
	local name="yazi-${arch}-unknown-linux-${libc}"
	if download "https://github.com/sxyazi/yazi/releases/latest/download/${name}.zip" "$TMP_DIR/yazi.zip"; then
		unzip -qo "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
		install -m 755 "$TMP_DIR/$name/yazi" "$TMP_DIR/$name/ya" "$LOCAL_BIN/"
		ok "yazi installé"
	else
		warn "yazi non installé"
	fi
}

install_fastfetch() {
	has fastfetch && return
	[ "$PM" = "apk" ] && return # binaire glibc uniquement
	step "fastfetch"
	local arch="amd64"
	[ "$ARCH" = "arm64" ] && arch="aarch64"
	local name="fastfetch-linux-${arch}"
	if download "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/${name}.tar.gz" "$TMP_DIR/ff.tar.gz"; then
		tar -xzf "$TMP_DIR/ff.tar.gz" -C "$TMP_DIR"
		install -m 755 "$TMP_DIR/$name/usr/bin/fastfetch" "$LOCAL_BIN/fastfetch"
		ok "fastfetch installé"
	else
		warn "fastfetch non installé"
	fi
}

# ------------------------------------------------------------------------------
# 2. Récupération du dépôt (utile avec curl | bash)
# ------------------------------------------------------------------------------
locate_repo() {
	if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/zsh/.zshrc" ]; then
		DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	elif [ -d "$DOTFILES/.git" ]; then
		step "Mise à jour de $DOTFILES"
		git -C "$DOTFILES" pull --ff-only || warn "git pull impossible, on garde la version locale"
	else
		step "Clonage dans $DOTFILES"
		git clone "$REPO_URL" "$DOTFILES"
	fi
	ok "Dotfiles : $DOTFILES"
}

# ------------------------------------------------------------------------------
# 3. Oh My Zsh, plugins zsh et tmux
# ------------------------------------------------------------------------------
clone_or_pull() { # clone_or_pull URL DEST
	if [ -d "$2/.git" ]; then
		git -C "$2" pull --ff-only -q || true
	else
		git clone --depth 1 -q "$1" "$2"
	fi
}

install_shell_plugins() {
	step "Oh My Zsh"
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
			"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	fi
	local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
	clone_or_pull https://github.com/zsh-users/zsh-autosuggestions "$custom/zsh-autosuggestions"
	clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting "$custom/zsh-syntax-highlighting"
	ok "Oh My Zsh + plugins installés"

	step "tmux (tpm)"
	clone_or_pull https://github.com/tmux-plugins/tpm "$CONFIG/tmux/plugins/tpm"
}

install_tmux_plugins() {
	# Après les liens : tpm lit tmux.conf pour connaître la liste des plugins
	"$CONFIG/tmux/plugins/tpm/bin/install_plugins" >/dev/null \
		&& ok "Plugins tmux installés" || warn "Plugins tmux : lance prefix + I dans tmux"
}

# ------------------------------------------------------------------------------
# 4. Liens symboliques (l'existant est sauvegardé en .bak.<date>)
# ------------------------------------------------------------------------------
link() { # link SOURCE (relatif au dépôt) CIBLE
	local src="$DOTFILES/$1" dest="$2"
	[ -e "$src" ] || die "Introuvable : $src"
	if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
		ok "$dest"
		return
	fi
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		mv "$dest" "$dest.bak.$STAMP"
		warn "$dest sauvegardé en $dest.bak.$STAMP"
	fi
	mkdir -p "$(dirname "$dest")"
	ln -s "$src" "$dest"
	ok "$dest → $src"
}

link_all() {
	step "Liens symboliques"
	link zsh/.zshrc               "$HOME/.zshrc"
	link zsh/.zshenv              "$HOME/.zshenv"
	link zsh/.zprofile            "$HOME/.zprofile"
	link git/gitconfig            "$HOME/.gitconfig"
	link git/ignore               "$CONFIG/git/ignore"
	link nvim                     "$CONFIG/nvim"
	link tmux/tmux.conf           "$CONFIG/tmux/tmux.conf"
	link yazi                     "$CONFIG/yazi"
	link btop/btop.conf           "$CONFIG/btop/btop.conf"
	link fastfetch/config.jsonc   "$CONFIG/fastfetch/config.jsonc"
	if [ "$OS" = "Darwin" ]; then
		link macos/aerospace/aerospace.toml "$CONFIG/aerospace/aerospace.toml"
	fi
}

# ------------------------------------------------------------------------------
# 5. zsh comme shell par défaut
# ------------------------------------------------------------------------------
set_default_shell() {
	local zsh_path
	zsh_path="$(command -v zsh)" || return 0
	case "${SHELL:-}" in */zsh) return 0 ;; esac
	step "zsh comme shell par défaut"
	grep -qx "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | as_root tee -a /etc/shells >/dev/null
	chsh -s "$zsh_path" || as_root chsh -s "$zsh_path" "$(id -un)" \
		|| { warn "chsh a échoué : lance « chsh -s $zsh_path »"; return 0; }
	ok "Shell par défaut : $zsh_path"
}

# ------------------------------------------------------------------------------
# Exécution
# ------------------------------------------------------------------------------
if [ "$LINK_ONLY" -eq 0 ]; then
	install_packages
	if [ "$OS" = "Linux" ]; then
		install_zoxide
		install_yazi
		install_fastfetch
	fi
fi
locate_repo
[ "$LINK_ONLY" -eq 0 ] && install_shell_plugins
link_all
if [ "$LINK_ONLY" -eq 0 ]; then
	install_tmux_plugins
	if [ "$INSTALL_NVIM" -eq 1 ]; then
		bash "$DOTFILES/nvim/install.sh" ${NVIM_ARGS[@]+"${NVIM_ARGS[@]}"}
	fi
	set_default_shell
fi

step "Terminé 🎉"
echo "  • Ouvre un nouveau terminal (ou : exec zsh)"
echo "  • Réglages propres à la machine : ~/.zshrc.local (non versionné)"
exit 0
