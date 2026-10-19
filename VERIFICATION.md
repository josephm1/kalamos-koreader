# Source publication checks — 19 October 2026

- Exported native project builds its three AAR modules independently: device API, Bigme provider and KOReader bridge.
- Native unit tests:49 passed, zero failures/errors/skips.
- Handwriting portable Lua suite passes, including persistence/recovery, toolbar/canvas ownership and background lifecycle cases.
- Independent TOC/book sharing:29 checks pass.
- Node integration/export/packaging checks:8 pass. The monorepo-only build-script check now checks this export's native build helper.
- All seven current patches apply cleanly to temporary extractions of the exact pinned upstream reader/base/launcher commits. Check-only made no changes to the real upstream checkouts.
- Source-only credential-pattern scan: no matches. No private books, notes, captures, certificates, machine settings or build artifacts are tracked.

A fresh full KOReader engine/APK build and physical acceptance are not part of this source publication. User owns panel, pen, rotation, navigation and app-switch testing. Existing device reader is unchanged.
