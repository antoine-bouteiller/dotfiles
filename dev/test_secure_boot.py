"""Run with: python3 -m unittest dev/test_secure_boot.py"""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'apps/x86_64-linux/secure-boot'
IGNORED = '''/boot/EFI/Microsoft/Boot/bootmgfw.efi is not signed
/boot/EFI/Microsoft/Boot/en-US/bootmgfw.efi.mui is not signed
/boot/EFI/nixos/nixos-generation-1.efi is not signed
'''


class SecureBootTest(unittest.TestCase):
    def run_script(self, verify):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            sudo = tmp / 'sudo'
            verify_file, log = tmp / 'verify', tmp / 'enroll.log'
            verify_file.write_text(verify)
            sudo.write_text('''#!/bin/sh
case "$1 $2 $3" in
  "sbctl status --json") printf '%s\\n' '{"secure_boot": false, "setup_mode": true}' ;;
  "sbctl verify ") cat "$VERIFY" ;;
  "sbctl enroll-keys --microsoft") printf '%s\\n' "$*" >> "$ENROLL_LOG" ;;
  *) echo "unexpected sudo: $*" >&2; exit 99 ;;
esac
''')
            sudo.chmod(0o755)
            env = os.environ | {'PATH': f'{tmp}:{os.environ["PATH"]}',
                                'VERIFY': str(verify_file), 'ENROLL_LOG': str(log)}
            result = subprocess.run([SCRIPT], text=True, capture_output=True, env=env)
            return result, log.read_text() if log.exists() else ''

    def test_windows_and_raw_nixos_warnings_enroll_microsoft_keys(self):
        result, enrolled = self.run_script(IGNORED)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(enrolled, 'sbctl enroll-keys --microsoft\n')

    def test_other_unsigned_efi_files_block_enrollment(self):
        for path in ('/boot/EFI/systemd/systemd-bootx64.efi',
                     '/boot/EFI/BOOT/BOOTX64.EFI',
                     '/boot/EFI/Linux/nixos.efi',
                     '/boot/EFI/fedora/shimx64.efi'):
            with self.subTest(path=path):
                result, enrolled = self.run_script(IGNORED + f'{path} is not signed\n')
                self.assertEqual(result.returncode, 1)
                self.assertIn(path, result.stderr)
                self.assertEqual(enrolled, '')


if __name__ == '__main__':
    unittest.main()
