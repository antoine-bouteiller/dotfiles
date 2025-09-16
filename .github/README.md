# config

## Zsh installation

Add this to .zshrc

```bash
DOTDIR=~/.config/dotfiles
git clone git@github.com:antoine-bouteiller/config.git $DOTDIR

# source the .zshenv from DOTDIR
echo ". $DOTDIR/zsh/.zshenv" > ~/.zshenv

# start a new zsh session
zsh
```
