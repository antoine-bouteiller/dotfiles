# config

## Zsh installation

Add this to .zshrc

```bash
ZDOTDIR=~/.config/zsh
git clone git@github.com:antoine-bouteiller/config.git $ZDOTDIR

# source the .zshenv from ZDOTDIR
ln -s ~/.config/zsh/.zshenv ~/.zshenv

# start a new zsh session
zsh
```

## Utilities

```bash
curl https://get.volta.sh | bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install thefuck
```
