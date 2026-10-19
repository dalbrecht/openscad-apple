import importlib.util
import pathlib
import subprocess
import sys
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
            (root / 'Example.ui').write_text('''<ui><widget class="QDialog" name="Dialog"><widget class="QSpinBox" name="steps"/><widget class="QGroupBox" name="options"><property name="checkable"><bool>true</bool></property></widget><widget class="CustomControl" name="custom"/></widget><action name="save"><property name="text"><string>&amp;Save</string></property><property name="shortcut"><string>Ctrl+S</string></property></action><customwidgets><customwidget><class>CustomControl</class><extends>QWidget</extends></customwidget></customwidgets></ui>''')
            rows = module.inventory(root)
            self.assertEqual({row['object'] for row in rows}, {'steps', 'save', 'custom', 'options'})
            self.assertTrue(all(row['status'] == 'unverified' for row in rows))
            self.assertEqual(next(row for row in rows if row['object'] == 'save')['shortcut'], 'Ctrl+S')

    def test_invalid_checkout_does_not_replace_existing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            output = root / 'existing.csv'
            output.write_text('accepted evidence must survive')
            for checkout in [root / 'missing', root / 'empty']:
                (root / 'empty/src/gui').mkdir(parents=True, exist_ok=True)
                result = subprocess.run([sys.executable, str(SCRIPT), str(checkout), str(output)],
                    capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(output.read_text(), 'accepted evidence must survive')
