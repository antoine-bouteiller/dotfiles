#!/bin/bash

if ([[ $OSTYPE == *darwin* ]]); then
   [[ ! $+commands[brew] ]] && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   [[ ! $+commands[zsh] ]] && brew install zsh
fi

DOTDIR=~/.config/dotfiles
ZSHDIR=$DOTDIR/zsh
[[ ! -d $DOTDIR ]] && git clone git@github.com:antoine-bouteiller/dotfiles.git $DOTDIR

# source the .zshenv from ZDOTDIR
echo ". $ZSHDIR/.zshenv" > ~/.zshenv

zsh
