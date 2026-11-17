#!/usr/bin/env bash
# Undo what install.sh did on this Mac. The repo itself is never touched.
#
#   ./cleanup.sh          remove the symlinks into this repo
#   ./cleanup.sh --deep   also delete plugin/cache folders that are rebuilt
#                         automatically (nvim plugins, Mason, tmux plugins)
#   add --yes             to skip the confirmation prompt
#
# Follow with ./install.sh for a fresh start.

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DEEP=0 YES=0
for arg in "$@"; do
	case "$arg" in
		--deep ) DEEP=1 ;;
		--yes | -y ) YES=1 ;;
		* ) die "unknown option: $arg (see the top of cleanup.sh)" ;;
	esac
done

# Rebuilt by install.sh / first launch. Losing them costs a re-download, plus
# nvim's local history (undo files, shada marks/registers) in ~/.local/state.
DEEP_DIRS=(
	"$HOME/.local/share/nvim"
	"$HOME/.local/state/nvim"
	"$HOME/.cache/nvim"
	"$HOME/.tmux/plugins"
)

# True if $1 is a symlink whose target is inside this repo (even if dangling).
points_into_repo() {
	[ -L "$1" ] || return 1
	local target dir
	target="$(readlink "$1")"
	case "$target" in /*) ;; *) target="$(dirname "$1")/$target" ;; esac
	dir="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" || return 1
	case "$dir/" in "$DOTFILES"/*) return 0 ;; esac
	return 1
}

links=() dirs=()
while IFS= read -r rel; do
	points_into_repo "$HOME/$rel" && links+=("$HOME/$rel")
done < <(managed_paths)
# Stale links to files that no longer exist in the repo.
for f in "$HOME"/.[!.]* "$HOME"/.config/*; do
	[ -L "$f" ] && [ ! -e "$f" ] && points_into_repo "$f" && links+=("$f")
done
if [ "$DEEP" -eq 1 ]; then
	for d in "${DEEP_DIRS[@]}"; do [ -e "$d" ] && dirs+=("$d"); done
fi

if [ "${#links[@]}" -eq 0 ] && [ "${#dirs[@]}" -eq 0 ]; then
	step "Nothing to clean up"
else
	step "This will remove"
	for f in ${links[@]+"${links[@]}"}; do printf '  link    %s\n' "$f"; done
	for d in ${dirs[@]+"${dirs[@]}"}; do printf '  folder  %s\n' "$d"; done

	if [ "$YES" -ne 1 ]; then
		printf '\nProceed? [y/N] '
		read -r reply
		case "$reply" in y | Y | yes ) ;; * ) echo "Aborted, nothing changed."; exit 1 ;; esac
	fi

	for f in ${links[@]+"${links[@]}"}; do rm "$f" && ok "removed $f"; done
	for d in ${dirs[@]+"${dirs[@]}"}; do rm -rf "$d" && ok "removed $d"; done
fi

# Things worth a look that this script deliberately leaves alone.
leftovers=()
for f in "$HOME"/.dotfiles-backup/* "$HOME"/.*.pre-* "$HOME"/.config/*.pre-* "$HOME"/.config/*backup*; do
	[ -e "$f" ] && leftovers+=("$f")
done
if [ "${#leftovers[@]}" -gt 0 ]; then
	step "Old backups (not touched - delete by hand once you no longer need them)"
	printf '  %s\n' "${leftovers[@]}"
fi

printf '\nRun ./install.sh to set this Mac up again.\n'
