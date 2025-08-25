# config

## Zsh installation

Add this to .zshrc

```bash
ZDOTDIR=~/.config/zsh
git clone git@github.com:antoine-bouteiller/config.git $ZDOTDIR

# source the .zshenv from ZDOTDIR
echo ". $ZDOTDIR/.zshenv" > ~/.zshenv

# start a new zsh session
zsh
```
