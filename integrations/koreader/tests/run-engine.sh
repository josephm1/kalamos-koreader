#!/usr/bin/env bash
# Run in a host development environment with CMake, FreeType/HarfBuzz and the CREngine deps.
# The build directory is disposable; the source checkout and original books are never modified.
set -euo pipefail
if [[ $# != 2 ]]; then echo "Usage: $0 /path/to/koreader /path/to/disposable-test-output" >&2; exit 2; fi
reader="$(cd "$1" && pwd)"
mkdir -p "$2"
output="$(cd "$2" && pwd)"
tests="$(cd "$(dirname "$0")" && pwd)"
engine="$reader/base/thirdparty/kpvcrlib/crengine"
unset LD_LIBRARY_PATH
cmake -S "$engine" -B "$output/host-engine" -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF -DFREETYPE=ON -DLIBUNIBREAK=OFF -DSRELL=OFF
cmake --build "$output/host-engine" --target crengine -j4
c++ -std=c++17 -I"$output/host-engine" -I"$engine/crengine/include" \
  $(pkg-config --cflags freetype2 harfbuzz fribidi libpng) \
  "$tests/engine/writing_space.cpp" "$output/host-engine/libcrengine.a" \
  $(pkg-config --libs freetype2 harfbuzz fribidi libpng libjpeg libwebpdecoder libwebpdemux libxxhash zlib libzstd) \
  -o "$output/engine-check"
python3 - "$output/test.epub" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], 'w') as book:
    book.writestr('mimetype', 'application/epub+zip')
    book.writestr('META-INF/container.xml', '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>')
    book.writestr('content.opf', '<package version="2.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="id"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="id">kalamos-space-test</dc:identifier><dc:title>Writing space test</dc:title><dc:language>en</dc:language></metadata><manifest><item id="c" href="chapter.xhtml" media-type="application/xhtml+xml"/><item id="c2" href="chapter2.xhtml" media-type="application/xhtml+xml"/></manifest><spine><itemref idref="c"/><itemref idref="c2"/></spine></package>')
    book.writestr('chapter.xhtml', '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Example</title></head><body style="padding-bottom:2000px"><p>First paragraph stays in place.</p><p>Second paragraph gets writing space.</p><p>Third paragraph moves down.</p><table><tr><td><p>Table paragraph</p></td></tr></table><p dir="rtl">RTL paragraph</p></body></html>')
    book.writestr('chapter2.xhtml', '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Second fragment</title></head><body><div>Second fragment for partial rendering checks.</div><!--' + 'cache fixture ' * 4000 + '--></body></html>')
PY
"$output/engine-check" "$output/test.html" "$reader/resources/fonts/urw/NimbusRomNo9L-Reg.cff"
"$output/engine-check" "$output/test.epub" "$reader/resources/fonts/urw/NimbusRomNo9L-Reg.cff"
