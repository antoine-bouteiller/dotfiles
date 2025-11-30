#!/bin/bash

set -e  # Exit on error

# ============================================================================
# Dotfiles Installation Script
# ============================================================================
# This script installs required dependencies and configures nushell with
# custom dotfiles for macOS, Fedora, and Debian/Ubuntu systems.
# ============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Configuration
readonly DOTFILES_DIR="${HOME}/.config/dotfiles"
readonly DOTFILES_REPO="git@github.com:antoine-bouteiller/dotfiles.git"

# ============================================================================
# Helper Functions
# ============================================================================

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# macOS Installation
# ============================================================================

install_macos() {
    print_info "Detected macOS"

    # Install Homebrew if not present
    if ! command_exists brew; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print_info "Homebrew already installed"
    fi

    # Install required packages
    local packages=("nushell" "starship" "bat" "zoxide")
    for package in "${packages[@]}"; do
        if ! command_exists "${package//nushell/nu}"; then
            print_info "Installing ${package}..."
            brew install "$package"
        else
            print_info "${package} already installed"
        fi
    done
}

# ============================================================================
# Fedora Installation
# ============================================================================

install_fedora() {
    print_info "Detected Fedora"

    # Install nushell
    if ! command_exists nu; then
        print_info "Installing nushell..."
        echo "[gemfury-nushell]
name=Gemfury Nushell Repo
baseurl=https://yum.fury.io/nushell/
enabled=1
gpgcheck=0
gpgkey=https://yum.fury.io/nushell/gpg.key" | sudo tee /etc/yum.repos.d/fury-nushell.repo > /dev/null
        sudo dnf install -y nushell
    else
        print_info "nushell already installed"
    fi

    # Install starship
    if ! command_exists starship; then
        print_info "Installing starship..."
        sudo dnf copr enable -y atim/starship
        sudo dnf install -y starship
    else
        print_info "starship already installed"
    fi

    if ! command_exists bat; then
        print_info "Installing bat..."
        sudo dnf install -y bat
    else
        print_info "bat already installed"
    fi

    if ! command_exists zoxide; then
        print_info "Installing bat..."
        sudo dnf install -y zoxide
    else
        print_info "zoxide already installed"
    fi
}

# ============================================================================
# Debian/Ubuntu Installation
# ============================================================================

install_debian_ubuntu() {
    print_info "Detected Debian/Ubuntu"

    # Update package list
    print_info "Updating package list..."
    sudo apt update

    # Install nushell
    if ! command_exists nu; then
        print_info "Installing nushell..."
        wget -qO- https://apt.fury.io/nushell/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/fury-nushell.gpg
        echo "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" | sudo tee /etc/apt/sources.list.d/fury.list
        sudo apt install -y nushell
    else
        print_info "nushell already installed"
    fi

    # Install starship
    if ! command_exists starship; then
        print_info "Installing starship..."
        sudo apt install -y starship
    else
        print_info "starship already installed"
    fi

    # Install bat
    if ! command_exists bat && ! command_exists batcat; then
        print_info "Installing bat..."
        sudo apt install -y bat
        mkdir -p ~/.local/bin
        ln -s /usr/bin/batcat ~/.local/bin/bat
    else
        print_info "bat already installed"
    fi

    # Install zoxide
    if ! command_exists zoxide; then
        print_info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    else
        print_info "zoxide already installed"
    fi
}

# ============================================================================
# Detect OS and Install Dependencies
# ============================================================================

detect_and_install() {
    if [[ "$OSTYPE" == *darwin* ]]; then
        install_macos
    elif [[ -f /etc/fedora-release ]]; then
        install_fedora
    elif [[ -f /etc/debian_version ]]; then
        install_debian_ubuntu
    else
        print_error "Unsupported operating system"
        print_error "This script supports macOS, Fedora, and Debian/Ubuntu"
        exit 1
    fi
}

# ============================================================================
# Clone or Update Dotfiles
# ============================================================================

setup_dotfiles() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        print_info "Dotfiles directory already exists"
    fi
}

# ============================================================================
# Configure Nushell
# ============================================================================

configure_nushell() {
    print_info "Configuring nushell..."

    local nu_config_dir
    nu_config_dir=$(nu -c 'echo $nu.default-config-dir')

    if [[ -z "$nu_config_dir" ]]; then
        print_error "Could not determine nushell config directory"
        exit 1
    fi

    # Create config directory if it doesn't exist
    mkdir -p "$nu_config_dir"

    # Write config to source dotfiles
    echo "source $DOTFILES_DIR/nu/init.nu" > "$nu_config_dir/config.nu"

    print_info "Nushell configuration complete"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    print_info "Starting dotfiles installation..."
    echo ""

    detect_and_install
    echo ""

    setup_dotfiles
    echo ""

    configure_nushell
    echo ""

    print_info "Installation complete! Execute nu to start"
}

# Run main function
main
