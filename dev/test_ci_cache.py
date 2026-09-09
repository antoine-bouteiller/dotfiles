import re
import unittest
from pathlib import Path
from types import SimpleNamespace as Context


WORKFLOW = (Path(__file__).resolve().parents[1] / '.github/workflows/build.yml').read_text()


def evaluate(name, **context):
    expression = re.search(
        rf'{name}:\s*(?:>-\s*)?\$\{{\{{(.*?)\}}\}}', WORKFLOW, re.DOTALL
    ).group(1)
    expression = ' '.join(expression.split()).replace('&&', 'and').replace('||', 'or')
    return eval(expression, {'__builtins__': {}}, context)


class CachePolicyTest(unittest.TestCase):
    def test_publish_and_token_access(self):
        repository = 'antoine-bouteiller/dotfiles'
        cases = [
            ('main push', 'push', 'refs/heads/main', '', '', '', True),
            ('main dispatch', 'workflow_dispatch', 'refs/heads/main', '', '', '', True),
            ('update PR', 'pull_request', 'refs/pull/example/merge', repository, 'flake-update', 'main', True),
            ('fork update PR', 'pull_request', 'refs/pull/example/merge', 'fork/dotfiles', 'flake-update', 'main', False),
            ('other PR', 'pull_request', 'refs/pull/example/merge', repository, 'feature', 'main', False),
            ('other base', 'pull_request', 'refs/pull/example/merge', repository, 'flake-update', 'feature', False),
            ('branch dispatch', 'workflow_dispatch', 'refs/heads/flake-update', '', '', '', False),
            ('branch push', 'push', 'refs/heads/flake-update', '', '', '', False),
        ]
        for name, event, ref, head_repo, head, base, allowed in cases:
            with self.subTest(name=name):
                github = Context(
                    event_name=event,
                    ref=ref,
                    repository=repository,
                    head_ref=head,
                    base_ref=base,
                    event=Context(pull_request=Context(head=Context(repo=Context(full_name=head_repo)))),
                )
                publish = evaluate('CACHIX_PUSH', github=github)
                self.assertEqual(publish, allowed)
                env = Context(CACHIX_PUSH=str(publish).lower())
                self.assertEqual(evaluate('skipPush', env=env), not allowed)
                self.assertEqual(
                    evaluate('authToken', env=env, secrets=Context(CACHIX_AUTH_TOKEN='write-token')),
                    'write-token' if allowed else '',
                )


if __name__ == '__main__':
    unittest.main()
