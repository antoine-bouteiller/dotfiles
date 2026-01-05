$POWERSHELL_DIR = "${HOME}/.dotfiles/powershell"

Get-ChildItem "${POWERSHELL_DIR}/configs" -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object { . $_ }

. "${POWERSHELL_DIR}/alias.ps1"
