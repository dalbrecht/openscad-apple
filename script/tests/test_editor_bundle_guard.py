import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]

class EditorBundleGuardTests(unittest.TestCase):
    def run_guard(self, status):
        with tempfile.TemporaryDirectory() as directory:
            tools = pathlib.Path(directory)
            for name in ['git', 'cmake', 'xcrun', 'pkill', 'codesign']:
                path = tools / name
                path.write_text('#!/bin/sh\necho UNEXPECTED_BUILD_OR_KILL >&2\nexit 98\n')
                path.chmod(0o700)
            pgrep = tools / 'pgrep'
            pgrep.write_text(f'#!/bin/sh\nexit {status}\n')
            pgrep.chmod(0o700)
            environment = dict(os.environ, PATH=f'{tools}:/usr/bin:/bin')
            result = subprocess.run([str(ROOT/'script/build_and_run.sh'), '--editor', '--build-only'],
                                    env=environment, capture_output=True, text=True, timeout=5)
            return result

    def test_running_editor_is_neither_killed_nor_replaced(self):
        result = self.run_guard(0)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Close OpenSCAD Editor', result.stderr)
        self.assertNotIn('UNEXPECTED_BUILD_OR_KILL', result.stderr)

    def test_failed_process_inspection_refuses_bundle_replacement(self):
        result = self.run_guard(3)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Cannot safely check', result.stderr)
        self.assertNotIn('UNEXPECTED_BUILD_OR_KILL', result.stderr)

if __name__ == '__main__': unittest.main()
