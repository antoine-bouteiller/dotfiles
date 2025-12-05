#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$dotfilesDir = "$env:USERPROFILE\.dotfiles"

$packages = @("Nushell.Nushell", "Starship.Starship", "sharkdp.bat", "ajeetdsouza.zoxide", "rsteube.Carapace", "jdx.mise", "ZedIndustries.Zed")
foreach ($package in $packages) {
    winget install --id $package --silent --accept-source-agreements --accept-package-agreements
}

$nuConfigDir = & nu -c '$nu.default-config-dir'
$zedDir = "$env:APPDATA\Zed"

if ($nuConfigDir -ne "$dotfilesDir\nushell") {
    if (Test-Path $nuConfigDir) {
        Remove-Item -Recurse -Force $nuConfigDir
    }
    New-Item -ItemType SymbolicLink -Path $nuConfigDir -Target "$dotfilesDir\nushell" -Force
}


if (Test-Path $zedDir) {
    Remove-Item -Recurse -Force $zedDir
}
New-Item -ItemType SymbolicLink -Path $zedDir -Target "$dotfilesDir\zed" -Force
