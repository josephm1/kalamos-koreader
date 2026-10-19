# Source publication checks — 19 October 2026

- Exported native project builds its three AAR modules independently: device API, Bigme provider and KOReader bridge.
- Native unit tests:49 passed, zero failures/errors/skips.
- Handwriting portable Lua suite passes, including persistence/recovery, toolbar/canvas ownership and background lifecycle cases.
- Independent TOC/book sharing:29 checks pass.
- Node integration/export/packaging checks:8 pass. The monorepo-only build-script check now checks this export's native build helper.
- All seven current patches apply cleanly to temporary extractions of the exact pinned upstream reader/base/launcher commits. Check-only made no changes to the real upstream checkouts.
- Source-only credential-pattern scan: no matches. No private books, notes, captures, certificates, machine settings or build artifacts are tracked.

A fresh full KOReader engine/APK build and physical acceptance are not part of this source publication. User owns panel, pen, rotation, navigation and app-switch testing. Existing device reader is unchanged.

Current-source recheck on 19 October 2026: plugin/engine/native code matches the active workspace.
Handwriting Lua, 29 TOC sharing checks, eight Node integration checks and native module tests/builds
pass again. Shared ink guide and module READMEs refreshed; no executable reader changes or device
installation. Manifest covers the complete tracked source plus the new READMEs.

Generic extension:42 API/provider and15 reader native tests pass, including five Standard editing
cases and two NativeActivity bridge cases. Standard reader Debug/Release AARs build independently.
Native source export now contains four modules (API, Standard, Bigme, reader bridge). Lua bridge
and all seven prepared upstream patches verify. Generic APK excludes Bigme and hidden-API classes;
physical pen/tablet acceptance is pending the owner's tests.

Complete generic native-ink candidate SHA256:82693d0108c4000f4ec82d861f6dfe8c27b417760308b8e089b5861ab7779043. Signature and packaged Lua verified;
DEX includes Standard provider/bridge and no Bigme/hidden-API implementation. No device install.

## Public source audit

All published revisions and tracked inputs scanned for common credential formats, private keys,
workstation paths, private device identifiers and unintended data/binary files. A historical local
handover path was removed; author/committer email metadata uses the account's GitHub privacy address.
No API keys, credentials, certificates, notebooks or personal books found in published source.
Existing generic APK is excluded because its third-party dictionary executable embeds a local build
path. The owner confirms working generic Android behavior on Huion Note E; no wider hardware claim.

## Attribution update — 19 October 2026

Documentation/licence-only update: upstream credits, full licence texts and component scopes
checked. Ink modules are GPL-3.0-only; reader AGPL and launcher/JNI MIT terms stay separate.
No runtime source changed; previous behavior/build results above remain historical evidence.
