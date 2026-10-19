import importlib.util
import pathlib
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / 'parity_ledger.py'

class ParityLedgerTests(unittest.TestCase):
    def test_records_actions_and_unlabelled_controls_without_claiming_parity(self):
        spec = importlib.util.spec_from_file_location('ledger', SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            (root / 'Example.ui').write_text('''<ui><widget class="QDialog" name="Dialog"><widget class="QSpinBox" name="steps"/></widget><action name="save"><property name="text"><string>&amp;Save</string></property><property name="shortcut"><string>Ctrl+S</string></property></action></ui>''')
            rows = module.inventory(root)
            self.assertEqual({row['object'] for row in rows}, {'steps', 'save'})
            self.assertTrue(all(row['status'] == 'unverified' for row in rows))
            self.assertEqual(next(row for row in rows if row['object'] == 'save')['shortcut'], 'Ctrl+S')
