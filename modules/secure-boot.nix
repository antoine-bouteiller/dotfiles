# Secure Boot (lanzaboote) + TPM2 unsealing for a LUKS root.
#
# Secure Boot is what makes a TPM2 key slot worth having: PCR 7 records the
# Secure Boot policy, and lanzaboote signs kernel+initrd with the sbctl keys, so
# an attacker's unsigned initrd never boots and the TPM never releases the key.
# Enrolling against PCR 7 alone (not 0) also survives firmware updates.
#
# Bring-up on a new host, in this order:
#   1. secureBoot.enable = false, install, boot. A fresh host has no keys under
#      /var/lib/sbctl, so lanzaboote could not sign and activation would fail.
#   2. sbctl create-keys, then secureBoot.enable = true and rebuild
#   3. sbctl verify, sbctl enroll-keys --microsoft, then restart
#   4. sbctl status -> must report Secure Boot enabled, otherwise stop here
#   5. systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 <luks-partition>
# Enrolling before step 4 seals against the wrong PCR 7 value.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.secureBoot;
in {
  imports = [inputs.lanzaboote.nixosModules.lanzaboote];

  options.secureBoot = {
    enable = lib.mkEnableOption "Secure Boot via lanzaboote, with TPM2 support in initrd";
  };

  config = lib.mkIf cfg.enable {
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    # lanzaboote replaces systemd-boot, which base-nixos.nix turns on by default.
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.initrd = {
      systemd = {
        enable = true;
        tpm2.enable = true;
      };
      # The TPM must be reachable in stage 1 to unseal the LUKS key.
      availableKernelModules = [
        "tpm_tis"
        "tpm_crb"
      ];
    };

    environment.systemPackages = with pkgs; [
      sbctl
      tpm2-tools
    ];
  };
}
