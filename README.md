# dotfiles

One repo for every Mac (home, work, ...): Alacritty, tmux, Neovim and zsh.

| Folder       | Linked to             | What                                    |
| ------------ | --------------------- | --------------------------------------- |
| `alacritty/` | `~/.config/alacritty` | terminal: font, padding, colours        |
| `tmux/`      | `~/.tmux.conf`        | tmux + tpm plugins                      |
| `nvim/`      | `~/.config/nvim`      | Neovim (lazy.nvim, pinned by lockfile)  |
| `zsh/`       | `~/.zshrc`            | oh-my-zsh, fzf, zoxide, eza, aliases    |

The files in `~` are symlinks into this repo, so editing a config anywhere
edits the repo. Sync between Macs with `git pull` / `git push`.

## Set up a Mac

**1. Install Homebrew** (this also installs git):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Clone and install:**

```sh
git clone https://github.com/Praneethsvch/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

**3. Install Alacritty by hand** (Homebrew no longer ships it): download the
`.dmg` from <https://github.com/alacritty/alacritty/releases>, drag it to
`/Applications`, then let macOS open it:

```sh
xattr -dr com.apple.quarantine /Applications/Alacritty.app
```

Open Alacritty and you are done. The first `nvim` launch spends a minute
installing LSP servers and treesitter parsers.

### What `install.sh` does

- Installs everything in the `Brewfile` (never upgrades what you already have).
- Installs oh-my-zsh and the tmux plugin manager if missing.
- Creates the symlinks. **Nothing is overwritten**: a file that is in the way
  is moved to `~/.dotfiles-backup/<timestamp>/` first.
- Installs Neovim plugins at the versions in `lazy-lock.json`.

It is safe to run again at any time, and that is the fix for most problems:
it only repairs what is missing. Any step that fails is listed as a warning at
the end; fix it and re-run.

`./install.sh --links-only` redoes just the symlinks.

## Day to day

- **Changed a config?** It is already in the repo: `git add -A && git commit && git push`.
- **On another Mac:** `git pull`, then `./install.sh` if the `Brewfile` or
  plugins changed.
- **Machine-specific settings** (work proxy, tokens, extra `PATH`) go in
  `~/.zshrc.local`. It is loaded last and is not tracked, so home and work can
  differ without touching the repo.
- **New tool to manage?** Add a folder that mirrors `$HOME` (for example
  `git/.gitconfig` or `foo/.config/foo/`) and run `./install.sh`.
- **Updated Neovim plugins** (`:Lazy update`)? Commit `lazy-lock.json` so the
  other Macs get the same versions.

## Clean up a messy Mac

For when links are broken, plugins misbehave, or you just want a known-good
state. Your configs live in the repo, so none of this loses them.

**Full reset** (the usual answer):

```sh
cd ~/dotfiles
git status                  # commit or discard local edits first
./cleanup.sh --deep
./install.sh
```

`cleanup.sh` shows exactly what it will remove and asks before doing it.

| Command               | Removes                                                         |
| --------------------- | --------------------------------------------------------------- |
| `./cleanup.sh`        | the symlinks into this repo, including stale ones               |
| `./cleanup.sh --deep` | the above, plus plugin and cache folders that get rebuilt (below) |

`--deep` deletes:

- `~/.local/share/nvim` - plugins, Mason LSP servers, treesitter parsers
- `~/.local/state/nvim` - undo history, marks, registers (**not** rebuilt)
- `~/.cache/nvim`
- `~/.tmux/plugins`

It never touches the repo, Homebrew packages, oh-my-zsh, `~/.zshrc.local`, or
backups. Old backups (`~/.dotfiles-backup/`, `~/*.pre-*`) are listed at the end
so you can delete them by hand once you are sure.

**Stop using these dotfiles on a Mac:** run `./cleanup.sh`, then move anything
you want back out of `~/.dotfiles-backup/`.

### Quick fixes

| Symptom                                 | Fix                                                        |
| --------------------------------------- | ---------------------------------------------------------- |
| Config changes not taking effect        | `./install.sh --links-only`                                |
| `command not found` for eza, fzf, ...   | `./install.sh`                                             |
| Neovim plugin errors after a pull       | in nvim: `:Lazy restore`                                   |
| Neovim still broken                     | `./cleanup.sh --deep && ./install.sh`                      |
| tmux plugins missing                    | in tmux: `prefix` + `I`                                    |
| Wrong font / boxes in Alacritty         | `brew install --cask font-source-code-pro`, restart Alacritty |
