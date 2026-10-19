## Public source audit — 19 October 2026

Owner authorized making this repository public after a confidentiality audit. Reviewed all tracked
files and every published revision. No credentials, signing keys, app certificates, books, notebooks,
local.properties or build outputs are published. Removed a workstation path from historical handover
text and normalized commit email metadata to the owner's GitHub privacy address. Source manifests
were regenerated. Private development history backups remain outside this repository.

The owner confirms generic Android operation on Huion Note E; development also targeted Bigme
e-ink. Scope is limited to these observations, not all Android/e-ink devices. No upstream PR.
An APK audit found a build-machine path in the bundled third-party dictionary executable; that APK
is not published here. Source and build instructions are the public testing route for now.

## Generic Android native ink — 19 October 2026

Neutral InkEditingController replaces direct Bigme dependencies. Build-time Standard/Bigme provider
selection, native-queue stylus forwarding, coalesced samples/pressure, session fencing, valid-Surface
readiness and incremental-to-complete stroke normalization implemented. Standard capture-only
editing, excluded controls and cropped chrome support preserve saved ink and host ownership.
Generic builds omit Bigme/hidden-API implementation. Existing Bigme native tests still pass.
Native tests:42 API/provider +15 reader tests pass. Portable Lua, eight integration checks and
export/asset-revision tests pass. Generic reader debug/release native AARs build independently;
complete generic native-ink APK is built from the prepared current engine. Physical tablet
acceptance belongs to the user. Separate private plugin and InkSDK repositories preserve boundaries.

## Current-source verification — 19 October 2026

Verified the integration plugins, engine patches and native modules against the canonical current
workspace: executable source is unchanged since the previous publication. Added current module
READMEs and refreshed the shared ink contract. Notes-only toolbar/checkbox changes do not alter
KOReader's implementation. Preserve the standalone build-script assertion in the export test.
Source manifest refreshed; no book/notebook/device artifacts or runtime data included.

# Source snapshot — 19 October 2026

Current Kalamos KOReader integration and independent TOC/book sharing plugin, with selected native dependencies and complete patches. Canonical source was exported from the canonical Kalamos workspace (base commit67c98ce plus current working changes). This snapshot includes later reader/canvas/toolbar/lifecycle fixes rather than the older review plugin snapshots. No historical mapper, companion app, MyScript certificate, private book, notebook or device evidence is included.

The upstream repository/base/launcher commits are pinned in integrations/review/upstream.lock.json. Native modules build independently. Full reader builds require the upstream source/toolchain as documented. Physical testing remains owner-owned; this publication does not install or rebuild KOReader on the device.

Publication checks:49 native unit tests, eight integration/export checks, handwriting Lua suite and29 sharing checks pass. All seven patches apply to clean temporary extractions of pinned upstream commits. See VERIFICATION.md. Export tooling expects a Git checkout when recording its source revision. The publication's source-manifest.json covers tracked source files, excluding itself.
