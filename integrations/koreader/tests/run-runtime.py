#!/usr/bin/env python3
"""Run saved-ink scenarios with an extracted official KOReader Linux runtime."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('runtime', type=Path, help='directory containing luajit and setupkoenv.lua')
args = parser.parse_args()
runtime = args.runtime.resolve()
if not (runtime / 'luajit').is_file() or not (runtime / 'setupkoenv.lua').is_file():
    parser.error('Expected an extracted KOReader Linux runtime directory.')
root = Path(__file__).resolve().parents[1]
plugin = root / 'kalamos.koplugin' if (root / 'kalamos.koplugin').is_dir() else root
with tempfile.TemporaryDirectory(prefix='koreader-ink-runtime-') as temporary:
    subprocess.run([str(runtime / 'luajit'), str(root / 'tests/engine/ink_store.lua'),
                    str(plugin), temporary], cwd=runtime, check=True)
