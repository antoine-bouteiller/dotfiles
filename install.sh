#!/bin/bash

set -e

readonly dotfiles_dir="${HOME}/.dotfiles"

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

packages=("nushell" "starship" "bat" "zoxide" "carapace" "fish" "mise" "ghostty" "zed")
for package in "${packages[@]}"; do
    brew install "$package"
done

# Config directories
ghostty_dir="${HOME}/.config/ghostty"
zed_dir="${HOME}/.config/zed"
nu_config_dir=$(nu -c '$nu.default-config-dir')

mkdir -p "$ghostty_dir"
rm -f "$ghostty_dir/config"
ln -s "${dotfiles_dir}/ghostty" "$ghostty_dir/config"

rm -rf "$zed_dir"
ln -s "${dotfiles_dir}/zed" "$zed_dir"

if [ "$nu_config_dir" != "${dotfiles_dir}/nushell" ]; then
    rm -rf "$nu_config_dir"
    ln -s "${dotfiles_dir}/nushell" "$nu_config_dir"
fi
