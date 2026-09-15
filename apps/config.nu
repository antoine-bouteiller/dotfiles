# Shared by local installation and remote bootstrap; hosts/base.nix reads the same settings.
const settings_file = path self ../lib/nix-settings.json
export const generations_to_keep = 2

export def nix-config []: nothing -> string {
  open $settings_file
  | transpose key value
  | each {|setting| $"extra-($setting.key) = ($setting.value | str join ' ')" }
  | str join "\n"
}
