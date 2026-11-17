# shellcheck shell=bash
# Shared helpers for install.sh and cleanup.sh. Sourced, not executed.
#
# Repo layout: one folder per tool, mirroring $HOME.
#   zsh/.zshrc                      -> ~/.zshrc
#   tmux/.tmux.conf                 -> ~/.tmux.conf
#   nvim/.config/nvim/              -> ~/.config/nvim        (whole folder)
#   alacritty/.config/alacritty/    -> ~/.config/alacritty   (whole folder)
#
# To manage a new tool, add a folder here and re-run ./install.sh. Nothing
# else needs editing.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ -t 1 ]; then
	C_OK=$'\033[32m' C_WARN=$'\033[33m' C_ERR=$'\033[31m' C_DIM=$'\033[2m' C_OFF=$'\033[0m'
else
	C_OK='' C_WARN='' C_ERR='' C_DIM='' C_OFF=''
fi

step() { printf '\n==> %s\n' "$*"; }
ok()   { printf '  %sok%s    %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '  %swarn%s  %s\n' "$C_WARN" "$C_OFF" "$*"; WARNINGS=$((WARNINGS + 1)); }
die()  { printf '%serror%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }
WARNINGS=0

# Prints every managed path relative to $HOME, one per line.
# A top-level entry in a package is linked as-is, except `.config`, whose
# children are linked individually so ~/.config itself stays a real folder.
managed_paths() {
	local pkg entry sub
	for pkg in "$DOTFILES"/*/; do
		pkg="${pkg%/}"
		for entry in "$pkg"/.[!.]* "$pkg"/*; do
			[ -e "$entry" ] || continue
			case "$(basename "$entry")" in
				.DS_Store | README* ) continue ;;
				.config )
					for sub in "$entry"/*; do
						[ -e "$sub" ] && printf '%s\n' "${sub#"$pkg"/}"
					done ;;
				* ) printf '%s\n' "${entry#"$pkg"/}" ;;
			esac
		done
	done
}

# Prints the repo source for a managed path (first package that has it).
source_for() {
	local pkg
	for pkg in "$DOTFILES"/*/; do
		if [ -e "$pkg$1" ]; then printf '%s\n' "$pkg$1"; return 0; fi
	done
	return 1
}
