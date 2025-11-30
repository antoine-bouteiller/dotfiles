source ./configs/mod.nu
source ./aliases/mod.nu

$env.PATH = [
    $env.HOME/.local/bin,
    ...$env.PATH
]

$env.config.show_banner = false
