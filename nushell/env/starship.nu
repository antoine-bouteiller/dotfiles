export const STARSHIP_INIT_PATH = ($nu.cache-dir | path join starship init.nu)

export-env {
    $env.STARSHIP_CONFIG = $"($env.HOME)/.dotfiles/starship.toml"
	mkdir ($STARSHIP_INIT_PATH | path dirname)
	starship init nu | save -f $STARSHIP_INIT_PATH
}
