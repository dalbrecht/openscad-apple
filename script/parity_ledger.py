#!/usr/bin/env python3
"""Inventory Qt Designer actions and input controls; never infer behavioral parity.

Usage: python3 script/parity_ledger.py CORE_CHECKOUT OUTPUT.csv
Only versioned upstream GUI XML is read. Dynamic behavior requires the manual ledger.
"""
import csv
import pathlib
import sys
import xml.etree.ElementTree as ET

CONTROLS = {'QCheckBox', 'QRadioButton', 'QComboBox', 'QSpinBox', 'QDoubleSpinBox',
            'QLineEdit', 'QPushButton', 'QToolButton', 'QSlider', 'QTextEdit',
            'QPlainTextEdit', 'QFontComboBox', 'QKeySequenceEdit', 'QListWidget',
            'QTreeWidget', 'QTableWidget', 'QTableView', 'QTextBrowser', 'QDialogButtonBox'}
FIELDS = ['id', 'source', 'object', 'kind', 'label', 'shortcut', 'status',
          'native_equivalent', 'issue', 'fixture', 'evidence', 'differences']

def inventory(gui_root):
    """Return deterministic, unverified rows including controls with no label."""
    gui_root = pathlib.Path(gui_root)
    if not gui_root.is_dir():
        raise ValueError(f'Qt GUI directory does not exist: {gui_root}')
    paths = sorted(gui_root.rglob('*.ui'))
    if not paths:
        raise ValueError(f'No Qt Designer forms found in: {gui_root}')
    rows = []
    for path in paths:
        tree = ET.parse(path)
        relative = path.relative_to(gui_root).as_posix()
        custom_classes = {item.findtext('class') for item in tree.iter('customwidget')}
        for item in tree.iter():
            if item.tag != 'action' and not (item.tag == 'widget' and (item.get('class') in CONTROLS | custom_classes or item.findtext("property[@name='checkable']/bool") == 'true')):
                continue
            name = item.get('name', '')
            properties = {prop.get('name'): ''.join(prop.itertext()).strip()
                          for prop in item.findall('property')}
            row = dict.fromkeys(FIELDS, '')
            row.update(id=f'{relative}:{name}', source=relative, object=name,
                       kind=item.get('class', 'QAction'), label=properties.get('text', ''),
                       shortcut=properties.get('shortcut', ''), status='unverified')
            rows.append(row)
    return rows

if __name__ == '__main__':
    root, output = map(pathlib.Path, sys.argv[1:])
    rows = inventory(root / 'src/gui')
    if not rows:
        raise ValueError('Qt forms contain no inventory rows')
    with output.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, FIELDS)
        writer.writeheader()
        writer.writerows(rows)
