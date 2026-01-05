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

def "complete_zoxide" [context: string] {
    let guess = $context | split row " " | skip 1

    let subDirs = ls | where type == dir | get name
    let subDotDirs = ls .* | where type == dir | get name | skip 2 # . and ..
    let zoxideDirs = zoxide query --list --exclude $env.PWD -- ...$guess | lines | first 10 | each {|it|
        if ($it | str starts-with $env.PWD) {
            $it | path relative-to $env.PWD
        } else {
            $it
        }
    }
    let completions =  [$subDirs  $subDotDirs  $zoxideDirs] | compact | flatten | uniq
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

export alias cd = __zoxide_z
export alias cdi = __zoxide_zi
