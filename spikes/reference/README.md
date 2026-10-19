# Pinned Qt reference (development only)

The native application never links these dependencies. This reference exists for
behavioral comparison against upstream GUI tree `b9c7abb9a055808247dc67fc8f672213225bcf43`
(from upstream `7bbf603833e167712e9cc7ae3432001dc26817d0`). The isolated checkout was
core commit `65b79fac2aba2cb8911703a9e7a29949af8b7948`; its Qt tree is identical.

Reference-only Homebrew packages: opencsg, qtbase, qtsvg, qtmultimedia, qt5compat,
qscintilla2. Use the official Lib3MF 2.5.0 Darwin SDK from
https://github.com/3MFConsortium/lib3mf/releases/tag/v2.5.0 rather than disabling 3MF.
Initialize the pinned Clipper2, Manifold, mimalloc, sanitizers and MCAD submodules.

Configure a separate build with HEADLESS=OFF, NULLGL=OFF, APPLE_UNIX=ON,
ENABLE_NATIVE_PREVIEW=OFF and ENABLE_TESTS=OFF. Set Lib3MF_INCLUDE_DIRS to the
SDK's include/Bindings/Cpp and Lib3MF_LIBRARY to its universal dylib; set
PKG_CONFIG_PATH to its lib/pkgconfig and point Bison/Flex at Homebrew. Build the
openscad target and install into a private reference prefix. Set the staged
binary's rpath to the SDK lib directory and ad-hoc sign it. Installed share/openscad
contains shaders, locale, fonts, examples, libraries and color schemes; running an
uninstalled binary omits these resources. This is a local reference, not a
redistributable or notarized product.

`docs/feasibility/qt-reference.json` records the binary hash, SDK archive hash,
configuration switches, submodule pins and reported dependency versions. The
staged reference runs --version and --info without missing-shader errors. Its
Welcome window was inspected with bundled examples and the expected revision.

Reference render command:

```
openscad -o difference.png --imgsize=256,256 --camera=0,0,100,0,0,0 \
  --projection=p --viewall --autocenter difference.scad
```

The fixture is `difference() { cube(20,center=true); sphere(12,$fn=24); }`.
OpenCSG normalization reports two elements. Both reference and Metal images show
the Boolean opening. They use different camera-fit and background settings; these
images are feasibility evidence, not a pixel-equivalence baseline. Every ledger
behavior still needs reference/native acceptance fixtures.
