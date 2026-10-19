"""Build an isolated, ad-hoc-signed Finder feasibility host; never replace the editor."""
import pathlib
import plistlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2]
APP = pathlib.Path('/private/tmp/openscad-finder-spike/OpenSCADFinderProbe.app')

def run(*arguments):
    subprocess.run(arguments, check=True)

def plist(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(plistlib.dumps(value))

mac = APP / 'Contents/MacOS'
mac.mkdir(parents=True, exist_ok=True)
run('xcrun', 'swiftc', '-swift-version', '6', str(ROOT/'spikes/finder/Host.swift'), '-o', str(mac/'FinderProbe'))
uti = {'UTTypeIdentifier':'org.openscad.source', 'UTTypeConformsTo':['public.source-code'],
       'UTTypeTagSpecification':{'public.filename-extension':['scad']}}
plist(APP/'Contents/Info.plist', {'CFBundleIdentifier':'org.openscad.apple.finder-probe',
      'CFBundleExecutable':'FinderProbe', 'CFBundlePackageType':'APPL', 'CFBundleVersion':'1',
      'CFBundleName':'OpenSCAD Finder Probe', 'UTImportedTypeDeclarations':[uti],
      'UTExportedTypeDeclarations':[{'UTTypeIdentifier':'org.openscad.apple.feasibility-model',
        'UTTypeConformsTo':['public.data'],
        'UTTypeTagSpecification':{'public.filename-extension':['scadprobe']}}],
      'CFBundleDocumentTypes':[{'CFBundleTypeName':'SCAD source', 'CFBundleTypeRole':'Viewer',
                               'LSItemContentTypes':['org.openscad.source','org.openscad.apple.feasibility-model']}]})
ent = ROOT/'work/spikes/finder-entitlements.plist'
plist(ent, {'com.apple.security.app-sandbox':True, 'com.apple.security.files.user-selected.read-only':True})
for name, point, principal in [('Preview','com.apple.quicklook.preview','PreviewController'),
                                ('Thumbnail','com.apple.quicklook.thumbnail','ThumbnailProvider')]:
    extension = APP/f'Contents/PlugIns/{name}.appex'
    binary = extension/f'Contents/MacOS/{name}'
    binary.parent.mkdir(parents=True, exist_ok=True)
    run('xcrun','swiftc','-swift-version','6','-parse-as-library','-application-extension',
        '-emit-executable','-Xlinker','-e','-Xlinker','_NSExtensionMain',
        str(ROOT/f'spikes/finder/{name}.swift'),'-o',str(binary))
    plist(extension/'Contents/Info.plist', {'CFBundleIdentifier':f'org.openscad.apple.finder-probe.{name.lower()}',
          'CFBundleExecutable':name,'CFBundlePackageType':'XPC!','CFBundleVersion':'2',
          'CFBundleShortVersionString':'0.1','LSMinimumSystemVersion':'14.0',
          'CFBundleName':name,
          'NSExtension':{'NSExtensionPointIdentifier':point,'NSExtensionPrincipalClass':principal,
                        'NSExtensionAttributes':{'QLSupportedContentTypes':['org.openscad.source','org.openscad.apple.feasibility-model'],
                                                'QLSupportsSearchableItems':False,'QLIsDataBasedPreview':False,'QLThumbnailMinimumDimension':32}}})
    run('codesign','--force','--sign','-','--entitlements',str(ent),str(extension))
run('codesign','--force','--sign','-',str(APP))
print(APP)
