# Secure Boot (lanzaboote) + TPM2 unsealing for a LUKS root.
#
# Secure Boot is what makes a TPM2 key slot worth having: PCR 7 records the
# Secure Boot policy, and lanzaboote signs kernel+initrd with the sbctl keys, so
# an attacker's unsigned initrd never boots and the TPM never releases the key.
# Enrolling against PCR 7 alone (not 0) also survives firmware updates.
#
# Bring-up on a new host is scripted: `nix run .#bootstrap` creates the sbctl keys
# before nixos-install (lanzaboote cannot sign the first generation without them),
# then `nix run .#secure-boot`, re-run after each restart, enrolls the keys into the
# firmware and only afterwards the LUKS TPM2 slot -- enrolling before Secure Boot is
# active would seal against the wrong PCR 7 value.
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
