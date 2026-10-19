# Kalamos handwriting for KOReader

The active integration provides standard Android stylus and Bigme pen input, full-page handwriting, handwritten sticky notes,
pen text selection, saved-ink replay and Android lifecycle support for EPUB/PDF reading.
The Kalamos reader tab contains handwriting and sticky-note controls only.

Play, Learn and Agent, book maps/cards/glossaries, AI extraction, generated evidence, mapping badges,
notifications and companion reading routes were archived on 15 October 2026. The obsolete KOReader integration and earlier mapper have now been deleted. Standalone app
history remains in `archive/apps/{play,learn,agent}`; it is not an active build target.

Existing books and generated device data are not deleted. Handwriting keeps its established book ID
and `/sdcard/Kalamos/BookData/<book-id>/ink-annotations.json` path so existing strokes and sticky notes
remain available. The active store reads/writes only ink annotations; it does not extract prose,
generate maps, call AI or read old map/evidence files. Do not delete the BookData directory as part
of generated-data cleanup: it also contains user handwriting.

## Generic Android pen build — 19 October 2026

Select the public Android provider when preparing a modified reader:

```sh
KALAMOS_DEVICE=standard ./integrations/koreader/build.sh /path/to/koreader
cd /path/to/koreader
GRADLE_FLAGS='-PkalamosInk=true -PkalamosDevice=standard' ./kodev build android-arm64 --debug
GRADLE_FLAGS='-PkalamosInk=true -PkalamosDevice=standard' make TARGET=android-arm64 KODEBUG=1 update
```

The default preparation remains Bigme for compatibility; use KALAMOS_DEVICE=bigme explicitly
when desired. The selected build packages exactly one provider. The generic launcher excludes
Bigme classes and hidden-API bypass. The stock launcher (without kalamosInk) remains available
without any custom handwriting bridge. Do not confuse stock generic reading with the generic
**native-ink** build above.

The standard provider is the same public MotionEvent/SurfaceView pen layer used by Notes.
KOReader's NativeActivity has a separate native input queue: the Lua filter forwards owned stylus
contacts, including coalesced samples and pressure, through the narrow launcher adapter. The
bridge normalizes incremental samples into one completed stroke, fences queued events by session,
and waits for a valid Android Surface before enabling capture. Bigme keeps its daemon delivery;
it never uses this forwarding path. Generic tool erasing/selection use capture-only gestures and
ordinary Android presentation, without firmware waveforms. Existing notebook/annotation IDs and
save/layout logic are retained. Finger input stays with reader controls; hardware-specific eraser
buttons, palm rejection, coordinate placement, latency and lifecycle need owner tablet testing.

Automated tests and APK packaging establish a candidate, not physical pen acceptance. Ordinary
Android devices must expose a standard stylus for this path. No arbitrary manufacturer fast-ink
SDK is bundled. The independent plugin repository holds Lua/sharing sources; the InkSDK repository
holds device-api and Standard/Bigme providers, without Notes editor or user data.

## 2026-10-18 — Reader writing controls and EPUB spaces

The Kalamos top-bar page/pen icon is a direct toggle in the prepared reader. A tick enables
writing; pressing it again saves and removes the rail and edge tab. Collapsing the rail leaves
writing active. **Exit**, above Pen, saves current ink, disables Kalamos and hides all tools,
matching the checked top-bar toggle. Its door-and-arrow icon and full tooltip identify the action.
Exit and the checked top-bar toggle share one shutdown path. The former retained Read mode and
its return-to-writing state have been removed; collapsing the rail still keeps Kalamos active.
Normal reading and text selection return once Kalamos is off; stray holds while Pen owns capture
are ignored. Leaving a canvas retains the rail. Every rail icon has a short label, and quick
swatches show colour names. The native rail follows the supplied Scribe references: drawn tool icons,
black selected states, separate colour slots, a five-sample width strip and two-row swatch grid.
Canvas has a visible label. Sticky notes are created from text selection, so the rail has no Note button. Pen, Ballpoint and Brush are the actual
supported brush engines. Reselect Pen/Highlighter for its adjacent settings panel; colours and
widths change directly without a separate dialog. Options include docking.

For an EPUB in single-page view, choose **Canvas**, then tap the paragraph to add space below it.
Drag down for a taller canvas. A positioning line follows contact, then real text layout opens
space and writing starts in it. Selecting Canvas opens no instruction panel; there is no paragraph
picker, preview/apply sequence or second Write command. Select Pen to leave Canvas placement. The text-selection action remains an alternative.
Tap inside a saved canvas to reopen it; its solid black paper boundary identifies the writing region.
Canvas options resize, collapse or explicitly remove it. The collapsed marker expands and opens it.

Select text to see a compact four-action bar: Highlight, handwritten note, Look up and **⋮**.
The last action opens KOReader's complete selection menu with its existing commands. The compact
bar is anchored beside the selected passage. Exit Kalamos before selecting reader text.

Handwritten sticky notes use a flat bottom window, a slim **Handwritten note / Text note** header,
options and X. Tools dock inside the writing paper; its blank space is the writing area, without
an excerpt panel or a second outline. X saves; Text note opens KOReader's ordinary note editor.
**Writing options → Discard note changes** retains the previous handwriting rollback behavior.

Canvas placement now uses CREngine's nearest source word and reveals the paragraph tail, so a long
paragraph does not leave its inserted paper offscreen. Like Notes' Blank Lines tool, an existing
canvas has one moving-edge handle: use Canvas and drag inside its paper to grow/shrink that same
space. The final native vectors are saved before resizing. Ordinary taps reopen it for writing.
Popup outlines are painted after their children so filled controls cannot erase the side borders.
Finger dragging a canvas's lower grip adjusts its height instead of scrolling the book. The EPUB
engine also supports normal headings and final text div/blockquote blocks for space insertion.

The first engine extension supports normal left-to-right paragraphs outside tables, lists and
floating content. It uses annotation-owned CSS padding and original source XPointer anchors;
EPUB bytes and DOM structure are unchanged. PDFs retain page ink/sticky notes, without insert
space. Multiple visible pages are not supported for spaces. This is paragraph insertion, not
arbitrary inline word wrapping around a free-shaped annotation.

`writing-spaces.json` is a separate versioned, atomically written layout/vector store alongside
legacy `ink-annotations.json`. Existing ink paths/book IDs are retained. New page ink has a
rendering/viewport signature; legacy ink adopts its first observed layout in reader settings.
Wrong-layout marks are withheld rather than silently shifted. Page-position ink no longer blocks
canvas changes. **Writing options → Original page handwriting** restores the marked layout and its
reading position; **Return to canvas layout** restores the canvas view. Existing vectors are never
erased or rewritten to guessed positions. New page marks carry a geometry-only canvas recipe so a
later resize can restore their marked layout. Geometry/style fingerprints, cached once per native
engine hash, recognize equivalent layouts despite CREngine's stylesheet-cache sentinel changes.
Observed old engine-hash aliases are saved in reader settings for existing page-ink compatibility.
Space ink is stored in local coordinates
with an aspect-preserving basis, and resize refuses clipping. Font/layout changes can require a
larger space before editing it. Do not downgrade to an older reader to edit a book with spaces.

Failed saves pause native capture and keep pending strokes for Retry; ordinary book Close is
vetoed until saving succeeds. Exceptional teardown retains a process-local recovery owner for
reopening the same book. This memory fallback cannot survive process death or guarantee storage
when disk writes fail. Sticky Cancel rolls back autosaved edits; conversion checks the actual
KOReader metadata flush before deleting the source space.

Native/engine changes require the complete prepared APK, not a Lua-only plugin install. The build
now verifies seven reader/native patches and includes engine/menu/icon changes in asset revision.
Canvas capture keeps input disabled until presentation completes; completed edits wait for pen idle.
The resize grip is limited to the visible lower-centre handle, and repeated contacts in an active
canvas do not restart capture. Canvas CSS uses quick chapter layout while KOReader prepares the full book in its existing
background worker. Kalamos pins the active layout and defers only the final cache/reload until the
writing toolbar is disabled. Canvas-local geometry replaces
whole-book fingerprinting on the canvas path. Tests and evidence:
`artifacts/koreader-canvas-background-2026-10-18/VERIFICATION.md`.
Physical pen, panel, rotation, page transitions and app-switch acceptance remain user-owned.

## Build

```bash
./integrations/koreader/build.sh /path/to/koreader
```

This prepares the plugin, Bigme/device AARs and narrow launcher/input patches. Then use KOReader's
`GRADLE_FLAGS=-PkalamosInk=true ./kodev build android-arm64` workflow for a 64-bit ARM device. Preparation rejects launchers containing obsolete companion wrappers; use a clean checkout. It no longer enables Turbo for AI requests or applies
Play-specific routing/import patches. Earlier private URI patches can remain dormant in an existing
checkout; use a clean pinned checkout when producing a fresh reader distribution.

The private APK bundles `kalamos.koplugin`. Do not also install it in `/sdcard/koreader/plugins/`:
KOReader does not deduplicate bundled and external copies. An external copy is only for plugin-only
iteration and must not coexist with the bundled copy.

Physical pen, page transition, rotation, app-switch, sticky-note and e-ink acceptance belongs to the
user. Automated checks and successful builds do not certify panel behavior.

Page-scoped replay deliberately retains the clean GU16 refresh. Its handoff uses KOReader's
two-tick repaint boundary instead of a fixed delay, and an active handwriting session keeps one
in-memory annotation document/index so page returns do not reread and decode the complete sidecar.
The bridge first primes the daemon buffer and presents the same replay bitmap through the bound
translucent ink surface, then performs the authoritative GU16 refresh on the next animation frame.
`KalamosBridge` logs UI-queue, surface, daemon-attach, replay-draw, preview outcome, animation-frame
wait, GU16-submit, and total timings under the `KalamosBridge` tag for device-side latency audits.

While a handwriting session is active, the launcher consumes the Android copy of every stylus or
eraser gesture before KOReader navigation sees it. The daemon still receives and paints the pen
through its independent input channel. Gesture ownership is held through UP/CANCEL, while finger
and mouse input remain available for normal KOReader navigation.

Full-page page turns retain one bound ink surface and daemon controller. The transition disables
pen input, drains the departing strokes, replaces both transient buffers with transparency without
an EPD refresh, waits for a stable destination view anchor, and reuses the same session for replay.
The damage rectangle passed to `SurfaceHolder.lockCanvas()` is copied because Android may expand its
in/out value; only the original tight stroke bounds are allowed to reach the final GU16 refresh.


Android background handoff is owned by `KalamosBridge`'s application lifecycle observer.
Pause/stop disables pen input and detaches the native daemon immediately, invalidating queued
replays and PixelCopy/chrome captures. It retains completed vectors for the next Lua checkpoint;
that checkpoint saves them against the departing page, then retires the old handwriting watcher.
Resume does not automatically reattach a retained book surface. Start handwriting explicitly
again after returning. No blanket white-panel refresh is introduced during the app switch.

## Review structure

See [the integration review guide](../README.md) for semantic ownership, local PR branches,
compatibility findings and remaining upstream work. Patches are grouped by purpose under
`patches/`: Android input, Android diagnostics, handwriting bridge and private build policy.

Extra crash diagnostics are enabled only by the launcher's `BuildConfig.DEBUG`: debug builds retain
logcat and copy the crash report to app external files. Release builds use stock crash-report
writing/log clearing and create no extra copy. This follows the actual build variant, not the
signing key. Old always-on diagnostic patches are rejected; use a clean launcher checkout.

## Saved-ink read failures

A missing sidecar starts an empty annotation document. An existing file that cannot be read or
decoded, has an unsupported schema/book identity, or has an invalid entry envelope instead produces
a visible error and blocks handwriting for that load. It is left in its original location and is
never replaced with an empty document. Restore a known-good copy while the reader is closed, then
reopen the book to retry; a successful load re-enables handwriting. No automatic repair, deletion
or storage migration is performed. New stroke collection does not start after a failed load.

Private asset revisions include the three Kalamos AARs as well as Lua/input sources, so native-only
changes invalidate the packaged revision. Preparation rejects older Lua-only revision patches.

Persistence tests run with `python3 integrations/koreader/tests/run.py`. To exercise actual
KOReader RapidJSON and filesystem behavior, run
`python3 integrations/koreader/tests/run-runtime.py /path/to/extracted/linux/koreader`. That optional
suite uses a fresh temporary directory and never reads device data or installed reader settings.

## Independent native build and storage configuration

Build the native modules directly with `tools/build-native.sh`; `build.sh` packages them into
KOReader. The repository and release source bundle already include the required modules and
licences. The former review-only source-copy/export toolchain has been retired.

The launcher adapter selects stock source/dependencies unless `-PkalamosInk=true` is explicit.
Stock SDK18/no-vendor and enabled SDK29 builds have both compiled in debug and release; launcher-only
evidence artifacts omit the reader engine and must not be installed. Bridge API1 capability checks
precede reader/input mutations. This is not proof of firmware compatibility or physical acceptance.

An advanced `kalamos_ink_directory` setting may select an absolute annotation directory. The default
remains the established BookData path. No file is automatically moved or merged. To change it, close
the reader, back up the old directory, copy the desired book-ID directories to an empty destination,
then set the directory and reopen a test book to verify its ink. Keep the backup until accepted.
Remove the setting to return to the old location. Invalid paths refuse handwriting rather than
silently choosing a different directory. This optional setting does not change the book-ID scheme.
