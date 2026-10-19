#!/usr/bin/env python3
"""Check a real export/package, including exclusion and changed-source refusal."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from zipfile import ZipFile

INTEGRATION = Path(__file__).resolve().parents[1]


class NativeSourceExportTest(unittest.TestCase):
    def test_export_is_self_contained_and_packages_only_hashed_sources(self):
        with tempfile.TemporaryDirectory(prefix='native-export-test-') as temporary:
            root=Path(temporary)
            source=root/'source'
            subprocess.run([sys.executable,str(INTEGRATION/'export-native.py'),str(source)],check=True,capture_output=True)
            manifest=json.loads((source/'source-manifest.json').read_text())
            self.assertEqual(set(manifest['modules']), {'foundation/device-api','devices/standard','devices/bigme','integrations/koreader/android-bridge'})
            self.assertNotIn('local.properties',manifest['files'])
            for module in manifest['modules']:
                self.assertIn(module+'/LICENSE',manifest['files'])
            (source/'local.properties').write_text('not-a-real-secret=do-not-package\n')
            (source/'build').mkdir()
            (source/'build/unrelated.apk').write_bytes(b'excluded')
            outputs=[root/'first.zip',root/'second.zip']
            for output in outputs:
                subprocess.run([sys.executable,str(INTEGRATION/'package-native.py'),str(source),'--output',str(output)],check=True,capture_output=True)
            self.assertEqual(outputs[0].read_bytes(),outputs[1].read_bytes())
            with ZipFile(outputs[0]) as archive:
                self.assertEqual(len(archive.namelist()),len(manifest['files'])+1)
                self.assertFalse(any('local.properties' in name or '/build/' in name for name in archive.namelist()))
            changed=source/next(name for name in manifest['files'] if name.endswith('.kt'))
            changed.write_text(changed.read_text()+'\n// changed after manifest\n')
            before=outputs[0].read_bytes()
            result=subprocess.run([sys.executable,str(INTEGRATION/'package-native.py'),str(source),'--output',str(outputs[0])],capture_output=True)
            self.assertNotEqual(result.returncode,0)
            self.assertEqual(before,outputs[0].read_bytes())


if __name__=='__main__':
    unittest.main()
