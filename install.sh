#!/usr/bin/env bash
# Set up (or repair) this Mac from the dotfiles repo. Safe to re-run any time.
#
#   ./install.sh               full setup: packages, links, plugins
#   ./install.sh --links-only  only (re)create the symlinks
#
# Nothing is ever overwritten: a file that is in the way is moved to
# ~/.dotfiles-backup/<timestamp>/ first.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

LINKS_ONLY=0
case "${1:-}" in
	"" ) ;;
	--links-only ) LINKS_ONLY=1 ;;
	* ) die "unknown option: $1 (see the top of install.sh)" ;;
esac

[ "$(uname -s)" = "Darwin" ] || die "this setup is for macOS"

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
TODO=()   # manual steps, printed at the end

# ---------------------------------------------------------------- packages --
install_packages() {
	step "Homebrew packages"
	local brew_bin=""
	for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew ""; do
		[ -n "$brew_bin" ] && [ -x "$brew_bin" ] && break
	done
	if [ -z "$brew_bin" ]; then
		die 'Homebrew is not installed. Install it, then re-run ./install.sh:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
	fi
	eval "$("$brew_bin" shellenv)"

	if brew bundle --file "$DOTFILES/Brewfile" --no-upgrade; then
		ok "Brewfile satisfied"
	else
		warn "some Brewfile entries failed (see above); continuing"
	fi

	# Homebrew disabled the alacritty cask (2026-09, unsigned app), so it is a
	# manual download.
	if [ -d /Applications/Alacritty.app ] || [ -d "$HOME/Applications/Alacritty.app" ]; then
		ok "Alacritty already installed"
	else
		TODO+=("Install Alacritty: download the .dmg from https://github.com/alacritty/alacritty/releases, drag it to /Applications, then run: xattr -dr com.apple.quarantine /Applications/Alacritty.app")
	fi
}

install_oh_my_zsh() {
	step "oh-my-zsh"
	if [ -d "$HOME/.oh-my-zsh" ]; then
		ok "already installed"
	# Plain clone rather than the official installer, which would replace ~/.zshrc.
	elif git clone --quiet --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"; then
		ok "installed"
	else
		warn "clone failed; the prompt theme will be missing until this succeeds"
	fi
}

# ------------------------------------------------------------------- links --
link_all() {
	step "Symlinks"
	local rel src dst
	while IFS= read -r rel; do
		src="$(source_for "$rel")" || continue
		dst="$HOME/$rel"

		if [ -L "$dst" ] && [ "$dst" -ef "$src" ]; then
			ok "~/$rel"
			continue
		fi
		if [ -L "$dst" ] || [ -e "$dst" ]; then
			mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
			mv "$dst" "$BACKUP_DIR/$rel" || { warn "could not move ~/$rel out of the way"; continue; }
			printf '  %smoved existing ~/%s to %s%s\n' "$C_DIM" "$rel" "$BACKUP_DIR/$rel" "$C_OFF"
		fi
		mkdir -p "$(dirname "$dst")"
		if ln -s "$src" "$dst"; then
			ok "~/$rel -> $src"
		else
			warn "could not link ~/$rel"
		fi
	done < <(managed_paths)
}

# ----------------------------------------------------------------- plugins --
install_tmux_plugins() {
	step "tmux plugins"
	local tpm="$HOME/.tmux/plugins/tpm"
	if [ ! -d "$tpm" ]; then
		git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "$tpm" \
			|| { warn "could not clone tpm; inside tmux press prefix + I later"; return; }
	fi
	if "$tpm/bin/install_plugins" >/dev/null 2>&1; then
		ok "plugins installed"
	else
		warn "plugin install failed; inside tmux press prefix + I"
	fi
}

install_nvim_plugins() {
	step "Neovim plugins (pinned to lazy-lock.json)"
	if nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1; then
		ok "plugins installed"
	else
		warn "headless install failed; open nvim and run :Lazy restore"
	fi
	printf '  %sLSP servers and treesitter parsers finish installing the first time you open nvim.%s\n' "$C_DIM" "$C_OFF"
}

# -------------------------------------------------------------------- main --
if [ "$LINKS_ONLY" -eq 1 ]; then
	link_all
else
	install_packages
	install_oh_my_zsh
	link_all
	install_tmux_plugins
	install_nvim_plugins
fi

step "Done"
for t in ${TODO[@]+"${TODO[@]}"}; do printf '  %stodo%s  %s\n' "$C_WARN" "$C_OFF" "$t"; done
if [ "$WARNINGS" -gt 0 ]; then
	printf '  %s%d warning(s) above.%s Fix them and re-run ./install.sh - it is safe to repeat.\n' "$C_WARN" "$WARNINGS" "$C_OFF"
	exit 1
fi
printf '  Restart Alacritty (or run: exec zsh) to pick everything up.\n'
