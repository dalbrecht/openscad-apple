# Dependencies and licenses

OpenSCAD core: GPL-2.0-or-later; exact revision in core-revision.txt. Upstream source,
COPYING, dependency notices and tests are preserved in the fork. CGAL: GPL/LGPL
components; Manifold: Apache-2.0; Clipper2: Boost Software License; Eigen: MPL-2.0;
Boost: BSL-1.0. Text/font dependencies include HarfBuzz, FreeType, Fontconfig and GLib;
archive/XML dependencies include libzip and libxml2; OpenSSL and double-conversion
retain their upstream licenses. Consult core COPYING and its bundled license files
for authoritative component terms. Apple system frameworks are SDK dependencies.

The prototype links Homebrew libraries dynamically and does not yet collect their
runtime closure into the bundle. ZIPs are for this development machine only.
Distribution license/notice packaging, signing and notarization remain deferred.

Host verification found Homebrew dependencies with macOS 26/27 deployment targets.
The Swift source declares macOS 14, but the current ZIPs must not be advertised as
macOS 14-compatible binaries. Rebuild/pin dependencies for that target before shipping.
