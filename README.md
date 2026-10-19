# Kalamos for KOReader

Source repository for the Kalamos KOReader adaptation: standard Android stylus and Bigme pen input, page handwriting, sticky notes, EPUB writing spaces, e-ink toolbar/lifecycle handling and ordinary Android excerpt/book sharing.

This is the complete Kalamos integration source and native build dependencies, exported from the active workspace on 19 October 2026. It is an integration repository: stock KOReader, its base engine and Android launcher are upstream dependencies pinned in `integrations/review/upstream.lock.json`. Other Kalamos apps, MyScript certificates, private books/notes, device captures, local credentials and build outputs are excluded.

## Contents

- `integrations/koreader/kalamos.koplugin`: reader handwriting and writing spaces.
- `integrations/koreader-toc-share/tocshare.koplugin`: chapter/book text sharing, metadata and cover.
- `integrations/koreader/patches` and `engine`: all required engine, launcher and reader changes.
- `foundation/device-api`, `devices/standard`, `devices/bigme`, `integrations/koreader/android-bridge`: standalone native source, with licenses/notices.

## Native build

Use JDK17 and Android SDK34. Set `ANDROID_HOME`, or create an untracked `local.properties` with `sdk.dir=/absolute/path/to/android-sdk`.

```sh
./gradlew :foundation:device-api:assembleDebug :devices:bigme:assembleDebug :integrations:koreader:android-bridge:assembleDebug
```

`tools/gradle.sh` additionally supports the local Android Studio Flatpak/JDK17 environment. No sibling Kalamos checkout is required.

## Full reader build

Install KOReader's documented Android build dependencies, then obtain its pinned source:

```sh
git clone https://github.com/koreader/koreader.git _upstream/koreader
git -C _upstream/koreader checkout --detach 892034c96ef6c4f8606809133d16bb604f8853c1
git -C _upstream/koreader submodule update --init --recursive
./integrations/koreader/build.sh _upstream/koreader
cd _upstream/koreader
GRADLE_FLAGS=-PkalamosInk=true ./kodev build android-arm64
GRADLE_FLAGS=-PkalamosInk=true make TARGET=android-arm64 update
```

Preparation validates every patch before applying changes and bundles the handwriting plugin/native AARs. The independent TOC sharing plugin can be installed separately; do not install a second external copy of a plugin already bundled in the reader. See each integration README for scope, storage compatibility, tests and packaging.

## Checks

```sh
python3 integrations/koreader/tests/run.py
python3 integrations/koreader-toc-share/tests/run.py
node --test integrations/koreader/tests/*.test.mjs
./gradlew testDebugUnitTest
```

Read `docs/devices/bigme/INK-WRITING-GUIDE.md` before modifying native ink behavior. The owner has confirmed the generic Android build working on a Huion Note E; development was primarily on Bigme e-ink. This does not establish compatibility with every Android tablet or e-ink firmware.

## Licensing

Original selected Kalamos code retains the owner-approved AGPL-3.0-or-later terms. Module/plugin LICENSE and NOTICE files preserve scope and third-party exceptions. KOReader and its engine/launcher retain their own upstream licenses. This is an independently maintained integration, not an official KOReader release. No upstream pull request is part of this publication.

## Generic Android handwriting candidate

The bridge now selects the provider through DeviceRegistry and supports the standard Android
pen module used by Notes. For a native-ink build on a generic tablet, prepare with
`KALAMOS_DEVICE=standard ./integrations/koreader/build.sh /path/to/koreader`, then use
`GRADLE_FLAGS='-PkalamosInk=true -PkalamosDevice=standard'` for the build/update commands above.
The default preparation remains Bigme; generic native-ink builds do not include Bigme or
hidden-API bypass classes. This is different from stock generic KOReader without native ink.

NativeActivity motion forwarding is required and included. It preserves historical samples and
pressure, prevents retired-session events, and delivers one complete saved stroke per gesture.
The generic provider waits for a valid Surface before capture. Device-specific pen/palm/eraser,
rotation, canvas placement and lifecycle behavior still need testing beyond the confirmed devices.

Plugin sources are included here: [TOC/book sharing](integrations/koreader-toc-share) and [handwriting](integrations/koreader/kalamos.koplugin).
Reusable API/providers: [kalamos-inksdk](https://github.com/josephm1/kalamos-inksdk).
These repositories are independent snapshots; this build resolves its own modules locally.

## Trying the handwriting build

Use the generic native-ink build command above for ordinary Android tablets. The standard provider
uses Android stylus events; it does not enable proprietary fast-ink modes on other manufacturers'
e-ink hardware. Bigme preparation selects the separate tested firmware integration. The writing
space feature requires the modified engine/launcher: a Lua-only plugin install cannot provide it.
Back up your reader settings and annotations before testing experimental builds.

The source was developed with substantial AI assistance; physical device testing was performed
by the project owner. Automated checks and exact source/build scope are recorded in VERIFICATION.md.
Public source history has been checked for credentials, local workstation paths and private data.
The existing APK contains an embedded third-party build path and is not included in this public
source publication. Build from source using your toolchain, or ask about a distributable test build.
