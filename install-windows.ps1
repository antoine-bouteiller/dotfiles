# ============================================================================
# Dotfiles Installation Script for Windows (PowerShell)
# ============================================================================
# This script installs required dependencies and configures nushell with
# custom dotfiles for Windows using winget.
# ============================================================================

#Requires -Version 5.1

# Stop on errors
$ErrorActionPreference = "Stop"

# Configuration
$DOTFILES_REPO = "git@github.com:antoine-bouteiller/dotfiles.git"
$DOTFILES_DIR = Join-Path $env:USERPROFILE ".config\dotfiles"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-WingetInstalled {
    if (Test-CommandExists "winget") {
        return $true
    }
    return $false
}

function Test-PackageInstalled {
    param([string]$PackageId)

    try {
        $result = winget list --id $PackageId --exact 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$DisplayName
    )

    if (Test-PackageInstalled -PackageId $PackageId) {
        Write-Info "$DisplayName already installed"
    }
    else {
        Write-Info "Installing $DisplayName..."
        winget install --id $PackageId --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Warning-Custom "Failed to install $DisplayName (exit code: $LASTEXITCODE)"
        }
    }
}

# ============================================================================
# Windows Installation
# ============================================================================

function Install-WindowsPackages {
    Write-Info "Installing packages for Windows using winget"
    Write-Host ""

    # Check if winget is available
    if (-not (Test-WingetInstalled)) {
        Write-Error-Custom "winget is not installed or not found in PATH"
        Write-Error-Custom "Please install winget (App Installer) from the Microsoft Store"
        Write-Error-Custom "https://www.microsoft.com/p/app-installer/9nblggh4nns1"
        exit 1
    }

    Write-Info "winget detected"
    Write-Host ""

    # Install packages
    Install-WingetPackage -PackageId "Nushell.Nushell" -DisplayName "Nushell"
    Install-WingetPackage -PackageId "Starship.Starship" -DisplayName "Starship"
    Install-WingetPackage -PackageId "sharkdp.bat" -DisplayName "Bat"
    Install-WingetPackage -PackageId "ajeetdsouza.zoxide" -DisplayName "Zoxide"

    # Refresh PATH environment variable
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Host ""
    Write-Warning-Custom "Common install locations:"
    Write-Warning-Custom "  - Nushell: $env:LOCALAPPDATA\Programs\Nushell"
    Write-Warning-Custom "  - Starship: $env:USERPROFILE\.cargo\bin"
    Write-Warning-Custom "  - Bat: $env:USERPROFILE\.cargo\bin"
    Write-Warning-Custom "  - Zoxide: $env:USERPROFILE\.cargo\bin"
}

# ============================================================================
# Clone or Update Dotfiles
# ============================================================================

function Install-Dotfiles {
    if (-not (Test-Path $DOTFILES_DIR)) {
        Write-Info "Cloning dotfiles repository to: $DOTFILES_DIR"

        # Create parent directory if it doesn't exist
        $parentDir = Split-Path $DOTFILES_DIR -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # Check if git is installed
        if (-not (Test-CommandExists "git")) {
            Write-Error-Custom "Git is not installed. Please install Git first."
            Write-Error-Custom "You can install Git using: winget install --id Git.Git"
            exit 1
        }

        git clone $DOTFILES_REPO $DOTFILES_DIR

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Failed to clone dotfiles repository"
            exit 1
        }
    }
    else {
        Write-Info "Dotfiles directory already exists at: $DOTFILES_DIR"
    }
}

# ============================================================================
# Configure Nushell
# ============================================================================

function Set-NushellConfig {
    Write-Info "Configuring nushell..."

    # Try to find nu executable
    $nuCommand = $null
    if (Test-CommandExists "nu") {
        $nuCommand = "nu"
    }
    else {
        # Try to find in common locations
        $commonPaths = @(
            "$env:LOCALAPPDATA\Programs\Nushell\nu.exe",
            "$env:PROGRAMFILES\Nushell\nu.exe",
            "$env:USERPROFILE\.cargo\bin\nu.exe"
        )

        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $nuCommand = $path
                # Add to current session PATH
                $nuDir = Split-Path $path -Parent
                $env:Path = "$nuDir;$env:Path"
                break
            }
        }
    }

    if (-not $nuCommand) {
        Write-Error-Custom "Nushell (nu) command not found in PATH"
        Write-Error-Custom "Please restart your terminal or add Nushell to your PATH"
        Write-Error-Custom "Then manually configure: $DOTFILES_DIR\nu\init.nu"
        exit 1
    }

    Write-Info "Found nushell at: $nuCommand"

    # Get nushell config directory
    try {
        $nuConfigDir = & $nuCommand -c 'echo $nu.default-config-dir' 2>$null

        if ([string]::IsNullOrWhiteSpace($nuConfigDir)) {
            # Use default Windows location
            $nuConfigDir = "$env:APPDATA\nushell"
            Write-Info "Using default config directory: $nuConfigDir"
        }
    }
    catch {
        # Use default Windows location
        $nuConfigDir = "$env:APPDATA\nushell"
        Write-Info "Using default config directory: $nuConfigDir"
    }

    # Create config directory if it doesn't exist
    if (-not (Test-Path $nuConfigDir)) {
        New-Item -ItemType Directory -Path $nuConfigDir -Force | Out-Null
    }

    # Convert Windows path separators to forward slashes for nushell
    $dotfilesSourcePath = $DOTFILES_DIR.Replace('\', '/')

    # Write config to source dotfiles
    $configFile = Join-Path $nuConfigDir "config.nu"
    $configContent = "source $dotfilesSourcePath/nu/init.nu"

    Set-Content -Path $configFile -Value $configContent -Encoding UTF8

    Write-Info "Nushell configuration written to: $configFile"
    Write-Info "Config sources: $dotfilesSourcePath/nu/init.nu"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

function Main {
    Write-Host ""
    Write-Info "Starting dotfiles installation for Windows..."
    Write-Info "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    try {
        Install-WindowsPackages
        Write-Host ""
        Write-Host "============================================================================" -ForegroundColor Cyan
        Write-Host ""

        Install-Dotfiles
        Write-Host ""
        Write-Host "============================================================================" -ForegroundColor Cyan
        Write-Host ""

        Set-NushellConfig
        Write-Host ""
        Write-Host "============================================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Info "Installation complete!"
        Write-Host ""
        Write-Info "Next steps:"
        Write-Info "  1. Close and reopen your terminal to refresh PATH"
        Write-Info "  2. Run 'nu' to start nushell"
        Write-Info "  3. Verify installation with: nu --version"
        Write-Host ""

        # Ask if user wants to start nushell now
        $response = Read-Host "Start nushell now? (y/N)"
        if ($response -match "^[Yy]$") {
            if (Test-CommandExists "nu") {
                Write-Info "Starting nushell..."
                Write-Host ""
                & nu
            }
            else {
                Write-Warning-Custom "Please restart your terminal and run 'nu' to start nushell"
            }
        }
    }
    catch {
        Write-Error-Custom "Installation failed: $_"
        exit 1
    }
}

# Check if running as Administrator (optional, but helpful)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning-Custom "Not running as Administrator. Some installations may require elevation."
    Write-Warning-Custom "If you encounter permissions errors, try running PowerShell as Administrator."
    Write-Host ""
}

# Run main function
Main
