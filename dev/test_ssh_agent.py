"""Run with: python3 -m unittest discover -s dev -p test_ssh_agent.py"""

import json
import os
import socket
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ForwardedAgentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.startup = json.loads(subprocess.check_output([
            'nix', 'eval', '--json', '.#homeConfigurations.vm.config', '--apply',
            'c: { bash = builtins.readFile c.home.file.".bashrc".source; '
            'zsh = c.programs.zsh.envExtra; }',
        ], cwd=ROOT, text=True))

    def shell(self, shell, home, agent=None, ssh=True):
        (home / ('.bashrc' if shell == 'bash' else '.zshenv')).write_text(
            self.startup[shell]
        )
        env = {'HOME': str(home), 'ZDOTDIR': str(home), 'PATH': os.environ['PATH'],
               'SHLVL': '0'}
        if ssh:
            env.update(SSH_CLIENT='127.0.0.1 12345 22',
                       SSH_CONNECTION='127.0.0.1 12345 127.0.0.1 22')
        if agent is not None:
            env['SSH_AUTH_SOCK'] = str(agent)
        return subprocess.check_output(
            [shell, '-c', 'printf "%s" "${SSH_AUTH_SOCK:-}"'], env=env, text=True
        )

    def agent(self, path):
        sock = socket.socket(socket.AF_UNIX)
        self.addCleanup(sock.close)
        sock.bind(str(path))
        sock.listen()
        return sock

    def test_reconnect_preserves_inherited_socket_path(self):
        for shell in self.startup:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory(dir='/tmp') as tmp:
                home = Path(tmp)
                first = home / 'first.sock'
                second = home / 'second.sock'
                stable = home / '.ssh/agent.sock'
                agent = self.agent(first)
                inherited = self.shell(shell, home, first)
                self.assertEqual(inherited, str(stable))
                self.assertEqual(stable.readlink(), first)
                self.assertEqual(stable.parent.stat().st_mode & 0o777, 0o700)
                # Nested shells must not make the link point to itself.
                self.assertEqual(self.shell(shell, home, stable), inherited)
                self.assertEqual(stable.readlink(), first)
                # A short-lived probe/second SSH session must not steal the link.
                probe = home / 'probe.sock'
                probe_agent = self.agent(probe)
                self.assertEqual(self.shell(shell, home, probe), inherited)
                self.assertEqual(stable.readlink(), first)
                probe_agent.close()
                probe.unlink()
                with socket.socket(socket.AF_UNIX) as client:
                    client.connect(inherited)
                agent.close()
                first.unlink()
                with socket.socket(socket.AF_UNIX) as client:
                    with self.assertRaises(FileNotFoundError):
                        client.connect(inherited)
                self.agent(second)
                self.assertEqual(self.shell(shell, home, second), inherited)
                self.assertEqual(stable.readlink(), second)
                # A process keeping the ORIGINAL environment reaches the new agent.
                with socket.socket(socket.AF_UNIX) as client:
                    client.connect(inherited)
                # Missing or stale forwarded sockets must not replace the live link.
                for missing in (None, first):
                    self.assertEqual(self.shell(shell, home, missing), inherited)
                    self.assertEqual(stable.readlink(), second)

    def test_no_forwarding_and_local_shell(self):
        for shell in self.startup:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory(dir='/tmp') as tmp:
                home = Path(tmp)
                stable = home / '.ssh/agent.sock'
                # A session started before forwarding also uses the durable name.
                self.assertEqual(self.shell(shell, home), str(stable))
                self.assertFalse(stable.is_symlink())
                local = home / 'local.sock'
                self.agent(local)
                self.assertEqual(self.shell(shell, home, local, ssh=False), str(local))
                self.assertFalse(stable.is_symlink())


if __name__ == '__main__':
    unittest.main()
