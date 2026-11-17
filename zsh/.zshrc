# Shared by every Mac. Anything specific to one machine (work proxies, tokens,
# extra PATH entries) goes in ~/.zshrc.local, which is not tracked.

# Homebrew. Needed here, not just in .zprofile, because Alacritty starts a
# non-login shell. Covers Apple Silicon and Intel.
if [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
[[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# fzf key bindings and completion
(( $+commands[fzf] )) && source <(fzf --zsh)

# Autosuggestions, accepted with ctrl+space
if [[ -r ${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
	source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
	bindkey '^ ' autosuggest-accept
fi

# Aliases, only when the tool behind them exists
(( $+commands[eza] )) && alias ls="eza --color=always --long --git --icons=always"
(( $+commands[cyme] )) && alias lsusb="cyme --lsusb"
if (( $+commands[zoxide] )); then
	eval "$(zoxide init zsh)"
	alias cd="z"
fi

# PATH
export PATH=/opt/SEGGER/JLink:$PATH
export LD_LIBRARY_PATH=/opt/SEGGER/JLink:$LD_LIBRARY_PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/rustup/bin:$PATH"

[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
