#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$dotfilesDir = "$env:USERPROFILE\.dotfiles"

$packages = @("Starship.Starship", "sharkdp.bat", "ajeetdsouza.zoxide", "jdx.mise", "ZedIndustries.Zed")
foreach ($package in $packages) {
    winget install --id $package --silent --accept-source-agreements --accept-package-agreements
}

$powershellProfileDir = Split-Path -Parent $PROFILE
$powershellProfile = $PROFILE
$zedDir = "$env:APPDATA\Zed"

if (-not (Test-Path $powershellProfileDir)) {
    New-Item -ItemType Directory -Path $powershellProfileDir -Force
}

if (Test-Path $powershellProfile) {
    Remove-Item -Force $powershellProfile
}
New-Item -ItemType SymbolicLink -Path $powershellProfile -Target "$dotfilesDir\powershell\profile.ps1" -Force

if (Test-Path $zedDir) {
    Remove-Item -Recurse -Force $zedDir
}
New-Item -ItemType SymbolicLink -Path $zedDir -Target "$dotfilesDir\zed" -Force
