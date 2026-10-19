# Source snapshot — 19 October 2026

Current Kalamos KOReader integration and independent TOC/book sharing plugin, with selected native dependencies and complete patches. Canonical source was exported from the canonical Kalamos workspace (base commit67c98ce plus current working changes). This snapshot includes later reader/canvas/toolbar/lifecycle fixes rather than the older review plugin snapshots. No historical mapper, companion app, MyScript certificate, private book, notebook or device evidence is included.

The upstream repository/base/launcher commits are pinned in integrations/review/upstream.lock.json. Native modules build independently. Full reader builds require the upstream source/toolchain as documented. Physical testing remains owner-owned; this publication does not install or rebuild KOReader on the device.

Publication checks:49 native unit tests, eight integration/export checks, handwriting Lua suite and29 sharing checks pass. All seven patches apply to clean temporary extractions of pinned upstream commits. See VERIFICATION.md. Export tooling expects a Git checkout when recording its source revision. The publication's source-manifest.json covers tracked source files, excluding itself.
