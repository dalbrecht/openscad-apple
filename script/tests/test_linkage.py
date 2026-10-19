import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]

class LinkageTests(unittest.TestCase):
    def test_inspection_failure_must_fail_gate(self):
        with tempfile.TemporaryDirectory() as directory:
            inspector = pathlib.Path(directory) / 'otool'
            inspector.write_text('#!/bin/sh\nexit 3\n')
            inspector.chmod(0o700)
            result = subprocess.run([str(ROOT / 'script/check_linkage.sh')],
                env=dict(os.environ, PATH=f'{directory}:/usr/bin:/bin'), capture_output=True)
            self.assertNotEqual(result.returncode, 0)
