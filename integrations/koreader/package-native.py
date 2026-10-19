#!/usr/bin/env python3
"""Package only hashed standalone source inputs; never include local settings or build outputs."""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
root = args.source.resolve()
manifest_path = root / 'source-manifest.json'
manifest = json.loads(manifest_path.read_text())
files = dict(manifest['files'])
files['source-manifest.json'] = hashlib.sha256(manifest_path.read_bytes()).hexdigest()
# Validate the complete input set before opening an output archive.
payloads = {}
for name, digest in sorted(files.items()):
    relative = Path(name)
    source = root / relative
    if relative.is_absolute() or '..' in relative.parts or source.is_symlink() or not source.resolve().is_relative_to(root):
        raise SystemExit(f'Unsafe manifest path: {name}')
    if any(part in ('build','.gradle','apps') for part in relative.parts) or relative.name == 'local.properties':
        raise SystemExit(f'Non-source input: {name}')
    raw = source.read_bytes()
    if hashlib.sha256(raw).hexdigest() != digest:
        raise SystemExit(f'Changed export input: {name}; regenerate the source snapshot')
    payloads[name] = raw
output = args.output.resolve()
output.parent.mkdir(parents=True, exist_ok=True)
temporary = output.with_suffix('.zip.tmp')
try:
    with ZipFile(temporary, 'w', compression=ZIP_DEFLATED) as archive:
        for name, raw in payloads.items():
            item = ZipInfo('koreader-native/' + name, date_time=(2026,10,15,0,0,0))
            item.compress_type = ZIP_DEFLATED
            item.external_attr = (0o100755 if name == 'gradlew' else 0o100644) << 16
            archive.writestr(item,raw)
    with ZipFile(temporary) as archive:
        assert archive.testzip() is None
        assert len(archive.namelist()) == len(payloads)
    temporary.replace(output)
finally:
    temporary.unlink(missing_ok=True)
digest = hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix('.zip.sha256').write_text(f'{digest}  {output.name}\n')
print(f'Packaged {len(payloads)} source inputs, SHA-256 {digest}')
