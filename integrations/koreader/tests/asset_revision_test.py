#!/usr/bin/env python3
"""Exercise the actual patched Make expression with source and native-only changes."""
from pathlib import Path
import subprocess
import tempfile
import unittest

PATCH = Path(__file__).resolve().parents[1] / 'patches/private-build/android-kalamos-asset-revision.patch'


class AssetRevisionTest(unittest.TestCase):
    def test_source_and_each_native_library_invalidate_assets(self):
        additions = [line[1:] for line in PATCH.read_text().splitlines()
                     if line.startswith('+') and not line.startswith('+++')]
        start = next(i for i, line in enumerate(additions) if line.startswith('KALAMOS_ASSET_REVISION ='))
        variable = []
        for line in additions[start:]:
            variable.append(line)
            if not line.endswith('\\'):
                break
        with tempfile.TemporaryDirectory(prefix='koreader-asset-revision-') as directory:
            root = Path(directory)
            files = [
                'plugins/kalamos.koplugin/main.lua',
                'plugins/kalamos.koplugin/resources/icons/kalamos.svg',
                'base/ffi/input_android.lua',
                'platform/android/luajit-launcher/app/libs/kalamos-device-api.aar',
                'platform/android/luajit-launcher/app/libs/kalamos-bigme.aar',
                'platform/android/luajit-launcher/app/libs/kalamos-koreader-bridge.aar',
            ]
            for name in files:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b'original')
            (root / 'Makefile').write_text('\n'.join(variable) + '\nprint:\n\t@echo $(KALAMOS_ASSET_REVISION)\n')

            def revision():
                value = subprocess.check_output(['make', '--no-print-directory', '-s', 'print'],
                                                cwd=root, text=True).strip()
                self.assertRegex(value, r'^[0-9a-f]{12}$')
                return value

            original = revision()
            self.assertEqual(revision(), original)
            for name in files:
                with self.subTest(component=name):
                    path = root / name
                    path.write_bytes(b'updated')
                    self.assertNotEqual(revision(), original)
                    path.write_bytes(b'original')
                    self.assertEqual(revision(), original)


if __name__ == '__main__':
    unittest.main()
