export const MISE_INIT_PATH = ($nu.cache-dir | path join mise init.nu)

export-env {
	mkdir ($MISE_INIT_PATH | path dirname)
	^mise activate nu | save $MISE_INIT_PATH --force
}
