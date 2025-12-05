export-env {
  $env.config = (
    $env.config?
		| default {}
    | upsert hooks.pre_prompt {|config|
      $config
      | get hooks?.pre_prompt?
      | default []
      | append {|| ^zoxide add -- $env.PWD }
    }
  )
}

def complete_zoxide [context: string] {
    let parts = $context | str trim --left | split row " " | skip 1 | each { str downcase }
    let completions = (
        ^zoxide query --list --exclude $env.PWD -- ...$parts
            | lines
            | each { |dir|
                if ($parts | length) <= 1 {
                    $dir
                } else {
                    let dir_lower = $dir | str downcase
                    let rem_start = $parts | drop 1 | reduce --fold 0 { |part, rem_start|
                        ($dir_lower | str index-of --range $rem_start.. $part) + ($part | str length)
                    }
                    {
                        value: ($dir | str substring $rem_start..),
                        description: $dir
                    }
                }
            })
    {
        options: {
            sort: false,
            completion_algorithm: substring,
            case_sensitive: false,
        },
        completions: $completions,
    }
}

export def --env __zoxide_z [...rest: string@'complete_zoxide'] {
	let arg0 = ($rest | append '~').0
	let path = (if ($arg0 | path expand | path type) == dir {
		$arg0
	} else {
		^zoxide query --exclude $env.PWD -- ...$rest | str trim --right --char "\n"
	})
	cd $path
}

export def --env __zoxide_zi  [...rest: string@'complete_zoxide'] {
	cd (^zoxide query -i -- ...$rest | str trim --right --char "\n")
}

export alias z = __zoxide_z
export alias cd = __zoxide_z
export alias zi = __zoxide_zi
