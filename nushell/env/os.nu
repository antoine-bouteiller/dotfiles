use std

export-env {
	match $nu.os-info.name {
		"macos" => {
			with-env { PATH: $env.PATH } {
				std path add '/opt/homebrew/bin'
				std path add '~/.local/bin'
			}
		}
		"linux" => {
			with-env { PATH: $env.PATH } {
				std path add '~/.local/bin'
			}
		}
		"windows" => {
		  $env.HOME = $env.USERPROFILE
		}
		_ => {}
	}
}
