"""Probe saved-source extraction and search without evaluating SCAD or changing settings."""
import json
import pathlib
import plistlib
import subprocess
import sys
import time

SENTINEL = 'OpenSCADAppleFeasibilitySentinel20261019'

def command(*arguments):
    """Run one bounded platform command and preserve its original diagnostics."""
    result = subprocess.run(arguments, capture_output=True, text=True, timeout=30)
    return {'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}

def read_metadata_text(data):
    """Read only the text field from XML, binary or OpenStep importer metadata."""
    try:
        values = plistlib.loads(data)
    except plistlib.InvalidFileException as cause:
        converted = subprocess.run(['plutil', '-convert', 'xml1', '-o', '-', '-'],
            input=data, capture_output=True, timeout=10)
        if converted.returncode:
            raise ValueError('Importer metadata conversion: ' + converted.stderr.decode('utf8', 'replace')) from cause
        values = plistlib.loads(converted.stdout)
    value = values.get('kMDItemTextContent', '') if isinstance(values, dict) else ''
    return value if isinstance(value, str) else ''

def run_probe(output, runner=command, wait_seconds=15, sleep=time.sleep):
    """Write a dedicated fixture/report; distinguish extraction from asynchronous search."""
    output = pathlib.Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    fixture = output / 'spotlight-probe.scad'
    fixture.write_text(f'// {SENTINEL}\nmodule feasibility_sentinel() {{ cube(2); }}\nfeasibility_sentinel();\n')
    attributes = output / 'spotlight-attributes.plist'
    attributes.unlink(missing_ok=True)
    extraction = runner('mdimport', '-t', '-d1', '-o', str(attributes), str(fixture))
    extracted_text, extraction_error = '', ''
    if extraction['status'] == 0 and attributes.exists():
        try:
            extracted_text = read_metadata_text(attributes.read_bytes())
        except (ValueError, plistlib.InvalidFileException, OSError, subprocess.TimeoutExpired) as error:
            extraction_error = str(error)
    imported = runner('mdimport', '-i', str(fixture))
    volume = runner('mdutil', '-s', '/System/Volumes/Data')
    report = {'sentinel': SENTINEL, 'extraction': extraction, 'extractionError': extraction_error,
              'sentinelExtracted': SENTINEL in extracted_text, 'import': imported,
              'volumeStatus': volume,
              'metadata': runner('mdls', '-name', 'kMDItemContentType', str(fixture))}
    deadline, attempts = time.monotonic() + max(0, wait_seconds), 0
    while True:
        result = runner('mdfind', '-onlyin', str(output), f'kMDItemTextContent == "*{SENTINEL}*"')
        attempts += 1
        found = str(fixture) in result['stdout'].splitlines()
        if result['status'] != 0: status = 'command_failed'
        elif found: status = 'found'
        elif 'read-only' in volume['stdout'].lower(): status = 'index_read_only'
        elif time.monotonic() >= deadline: status = 'timed_out'
        else:
            sleep(min(1, max(0, deadline - time.monotonic())))
            continue
        report.update(search=result, searchFoundFixture=found, searchStatus=status, searchAttempts=attempts)
        break
    (output / 'spotlight.json').write_text(json.dumps(report, indent=2) + '\n')
    return report

if __name__ == '__main__':
    report = run_probe(sys.argv[1])
    print(json.dumps({key: report[key] for key in ['sentinelExtracted', 'searchFoundFixture', 'searchStatus']}, indent=2))
