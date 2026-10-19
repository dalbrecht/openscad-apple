import importlib.util
import json
import pathlib
import plistlib
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[2] / 'spikes/spotlight/probe.py'

class SpotlightProbeTests(unittest.TestCase):
    def module(self):
        spec = importlib.util.spec_from_file_location('spotlight_probe', SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_xml_and_openstep_metadata_extract_actual_text_field(self):
        module = self.module()
        self.assertEqual(module.read_metadata_text(plistlib.dumps({'kMDItemTextContent':'sentinel'})), 'sentinel')
        self.assertEqual(module.read_metadata_text(b'{ kMDItemTextContent = "sentinel"; }'), 'sentinel')
        self.assertEqual(module.read_metadata_text(plistlib.dumps({'unrelated':'sentinel'})), '')

    def test_report_is_valid_json_and_waits_for_asynchronous_indexing(self):
        module = self.module()
        with tempfile.TemporaryDirectory() as directory:
            output = pathlib.Path(directory).resolve()
            fixture = output / 'spotlight-probe.scad'
            attempts = []
            def runner(*arguments):
                text = ''
                if arguments[0] == 'mdimport' and '-o' in arguments:
                    pathlib.Path(arguments[arguments.index('-o')+1]).write_bytes(
                        plistlib.dumps({'kMDItemTextContent':module.SENTINEL}))
                if arguments[0] == 'mdfind':
                    attempts.append(True)
                    if len(attempts) > 1: text = str(fixture) + '\n'
                return {'status':0,'stdout':text,'stderr':''}
            report = module.run_probe(output, runner=runner, wait_seconds=1, sleep=lambda _:None)
            self.assertTrue(report['sentinelExtracted'])
            self.assertTrue(report['searchFoundFixture'])
            self.assertEqual(report['searchStatus'], 'found')
            self.assertEqual(json.loads((output/'spotlight.json').read_text()), report)
            self.assertGreater(len(fixture.read_text().splitlines()), 1)
            self.assertIn('\nmodule ', fixture.read_text())
