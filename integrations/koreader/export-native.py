#!/usr/bin/env python3
"""Export a review-only standalone build from canonical native sources, never sync active apps."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
MODULES = ('foundation/device-api', 'devices/bigme', 'integrations/koreader/android-bridge')
parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path, help='new/empty directory for the standalone native source build')
args = parser.parse_args()
output = args.output.resolve()
if output.exists() and any(output.iterdir()):
    parser.error('Output must be new or empty; an existing export is never overwritten.')
if output == ROOT or ROOT in output.parents and not output.is_relative_to(ROOT / 'artifacts'):
    parser.error('Exports inside the repository belong under artifacts/.')
output.mkdir(parents=True, exist_ok=True)
files = []
for module in MODULES:
    base = ROOT / module
    selected = [base / 'build.gradle.kts', *sorted((base / 'src/main').rglob('*'))]
    selected.extend(base / name for name in ('LICENSE', 'NOTICE.md') if (base / name).exists())
    if (base / 'consumer-rules.pro').exists():
        selected.append(base / 'consumer-rules.pro')
    for source in selected:
        if source.is_symlink():
            raise SystemExit(f'Refusing symlink in native source export: {source}')
        if not source.is_file():
            continue
        if source.name not in ('LICENSE', 'NOTICE.md') and source.suffix not in ('.kts', '.kt', '.java', '.xml', '.pro'):
            raise SystemExit(f'Unreviewed source type: {source}')
        relative = source.relative_to(ROOT)
        if 'certificate' in relative.as_posix().lower():
            raise SystemExit(f'Refusing certificate source: {relative}')
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        files.append(relative.as_posix())
for name in ('gradlew', 'gradle/wrapper/gradle-wrapper.jar', 'gradle/wrapper/gradle-wrapper.properties'):
    target = output / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, target)
    files.append(name)
(output / 'build.gradle.kts').write_text('''plugins {
    id("com.android.library") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}
''')
(output / 'settings.gradle.kts').write_text('''pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "koreader-native-ink-review"
include(":foundation:device-api", ":devices:bigme", ":integrations:koreader:android-bridge")
''')
(output / 'gradle.properties').write_text('android.useAndroidX=true\n')
(output / '.gitignore').write_text('.gradle/\n**/build/\nlocal.properties\n')
(output / 'README.md').write_text('''# Standalone native ink build — local review export

This immutable source snapshot builds only the device API, Bigme provider and reader bridge.
Canonical development remains in Kalamos. No other apps, certificates, secrets, books, prebuilt
vendor SDK binaries, private settings or sibling repositories are needed.

Use JDK 17 and Android SDK platform 34; set ANDROID_HOME or your own local.properties, then run:

    ./gradlew :integrations:koreader:android-bridge:assembleDebug :integrations:koreader:android-bridge:assembleRelease --no-daemon

The wrapper pins Gradle 8.14.5; plugins pin AGP 8.2.2/Kotlin 1.9.22. The source manifest records
exact input hashes. Original exported Kalamos code is AGPL-3.0-or-later as approved by the rights holder;
module LICENSE/NOTICE files retain the scope and third-party exceptions. The build uses public
Android APIs plus runtime reflection into firmware-provided classes, and the declared Maven
HiddenApiBypass dependency. Firmware availability/permissions and physical behavior require testing.

The three build/outputs/aar libraries are consumed only by a launcher explicitly built with
-PkalamosInk=true. Stock launcher builds omit these libraries and retain the upstream SDK floor.
''')
files.extend(('build.gradle.kts', 'settings.gradle.kts', 'gradle.properties', '.gitignore', 'README.md'))
manifest = {'kind': 'local review export; original code AGPL-3.0-or-later; third-party terms retained',
            'kalamosHead': subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'], text=True).strip(),
            'modules': MODULES, 'files': {name: hashlib.sha256((output/name).read_bytes()).hexdigest() for name in sorted(files)}}
(output / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(f'Exported {len(files)} reviewed inputs to {output}')
