"""Exercise saved-source Spotlight extraction and search without evaluating SCAD.

Writes only a dedicated sentinel fixture and evidence to the supplied directory.
Does not change Spotlight settings, importers, privacy exclusions or user records.
"""
import json
import pathlib
import re
import subprocess
import sys

SENTINEL = 'OpenSCADAppleFeasibilitySentinel20261019'

def command(*arguments):
    result = subprocess.run(arguments, capture_output=True, text=True, timeout=30)
    return {'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}

if __name__ == '__main__':
    output = pathlib.Path(sys.argv[1]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    fixture = output / 'spotlight-probe.scad'
    fixture.write_text(f'// {SENTINEL}\nmodule feasibility_sentinel() {{ cube(2); }}\nfeasibility_sentinel();\n')
    attributes = output / 'spotlight-attributes.plist'
    attributes.unlink(missing_ok=True)
    extraction = command('mdimport', '-t', '-d1', '-o', str(attributes), str(fixture))
    extracted_text = ''
    if attributes.exists():
        extracted_text = attributes.read_text()
    report = {'sentinel': SENTINEL, 'extraction': extraction,
              'sentinelExtracted': bool(re.search(r'kMDItemTextContent\s*=\s*".*?' + SENTINEL, extracted_text, re.S)),
              'import': command('mdimport', '-i', str(fixture)),
              'volumeStatus': command('mdutil', '-s', '/System/Volumes/Data'),
              'metadata': command('mdls', '-name', 'kMDItemContentType', str(fixture)),
              'search': command('mdfind', '-onlyin', str(output),
                                f'kMDItemTextContent == "*{SENTINEL}*"')}
    report['searchFoundFixture'] = str(fixture) in report['search']['stdout'].splitlines()
    (output / 'spotlight.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ['sentinelExtracted','searchFoundFixture']}, indent=2))
