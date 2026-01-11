#!/bin/bash

set -e

readonly DOTDIR="${HOME}/.dotfiles"

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

packages=("nushell" "starship" "bat" "zoxide" "carapace" "fish" "mise" "ghostty" "zed")

for package in "${packages[@]}"; do
    brew install "$package"
done

if [ "$server_mode" = false ]; then
    ghostty_dir="${HOME}/.config/ghostty"
    zed_dir="${HOME}/.config/zed"

    mkdir -p "$ghostty_dir"
    rm -f "$ghostty_dir/config"
    ln -s "${DOTDIR}/ghostty" "$ghostty_dir/config"

    rm -rf "$zed_dir"
    ln -s "${DOTDIR}/zed" "$zed_dir"
fi

echo "source $DOTDIR/zsh/.zshenv" >> "$HOME/.zshenv"
