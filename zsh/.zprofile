# Homebrew (macOS Apple Silicon / Intel, ou Linuxbrew)
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$brew" ]; then
    eval "$("$brew" shellenv)"
    break
  fi
done
unset brew

# Docker Desktop
[ -d "$HOME/.docker/bin" ] && export PATH="$PATH:$HOME/.docker/bin"
