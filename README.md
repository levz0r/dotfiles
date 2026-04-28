# dotfiles

My personal config files for macOS.

## What's here

- [`wezterm/`](./wezterm) — WezTerm terminal config: Hebrew BiDi, Ghostty palette, powerline tab bar, custom status bar (battery / load / memory / time-of-day clock), macOS-style keybindings, ⌘+click to open links, and more.

## Install on a fresh Mac

```sh
# 1. WezTerm + fonts (Hebrew mono + Nerd Font symbols)
brew install --cask wezterm
brew install --cask font-jetbrains-mono font-miriam-mono-clm font-symbols-only-nerd-font

# 2. Symlink the config
git clone https://github.com/levz0r/dotfiles.git ~/dev/dotfiles
ln -s ~/dev/dotfiles/wezterm/wezterm.lua ~/.wezterm.lua

# 3. (Optional) Bell-on-long-command notifications
cat ~/dev/dotfiles/wezterm/zshrc-snippet.sh >> ~/.zshrc
```

Launch WezTerm. Plugins (currently none — using a custom in-config tab bar) would auto-clone on first run via `wezterm.plugin.require`.

## Notes

- Allow notification permissions for `osascript` the first time the bell fires.
- The status bar refreshes system stats every 5s (cached so updates are cheap).
- Hebrew text renders correctly because of `bidi_enabled = true` plus the Miriam Mono CLM fallback font.

### Optional: bell-on-long-command notifications

Append to `~/.zshrc` (rings the terminal bell — WezTerm turns it into a macOS notification — when any command takes more than 10s):

~~~zsh
zmodload zsh/datetime
__bell_pre() { __bell_start=$EPOCHSECONDS }
__bell_post() {
  local dur=$(( EPOCHSECONDS - ${__bell_start:-$EPOCHSECONDS} ))
  (( dur > 10 )) && print -n '\a'
  unset __bell_start
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec __bell_pre
add-zsh-hook precmd  __bell_post
~~~
