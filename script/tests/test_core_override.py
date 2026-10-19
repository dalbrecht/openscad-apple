import os
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]

class CoreOverrideTests(unittest.TestCase):
    def test_build_and_tests_select_same_explicit_core(self):
        result = subprocess.run(['make', '-n', 'test'], cwd=ROOT,
            env=dict(os.environ, OPENSCAD_CORE_PATH='/private/tmp/example-core'),
            capture_output=True, text=True, check=True)
        self.assertIn('/private/tmp/example-core/build-native/openscad-preview-worker', result.stdout)
        self.assertNotIn(str(ROOT / 'work/openscad-core/build-native'), result.stdout)
