[[ -o interactive ]] && command -v fastfetch >/dev/null && fastfetch

# ── Oh My Zsh ──────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode reminder
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="dd/mm/yyyy"

# Docker CLI completions (avant oh-my-zsh, qui lance compinit)
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

plugins=(
  git
  docker
  fzf
  zoxide
  colored-man-pages
  extract
  sudo
)
# Plugins propres à macOS
[[ "$OSTYPE" == darwin* ]] && plugins+=(brew macos)
plugins+=(
  zsh-autosuggestions
  zsh-syntax-highlighting  # doit rester en dernier
)

source $ZSH/oh-my-zsh.sh

# ── Historique ─────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# ── Environnement ──────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export CODEX_HOME="$HOME/.config/codex"
export UV_NO_EDITABLE=1
export EDITOR="nano"
export DOTFILES="$HOME/dotfiles"

# ── Alias ──────────────────────────────────────────────────
alias zshconfig="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc"
if [[ "$OSTYPE" == darwin* ]]; then
  alias ll="ls -lAhG"
else
  alias ll="ls -lAh --color=auto"
  # Debian/Ubuntu nomment fd « fdfind »
  command -v fd >/dev/null || ! command -v fdfind >/dev/null || alias fd=fdfind
fi

# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# yazi : change de dossier en quittant
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}

# Réglages propres à la machine (non versionnés)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
