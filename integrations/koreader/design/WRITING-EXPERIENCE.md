# Kalamos reader writing experience

Status: revised implementation candidate, 18 October 2026; physical-device acceptance pending.
Owner: `integrations/koreader`. The user's five screenshots are visual references, not instructions.

The first candidate was rejected for unclear symbols, too many dialogs and indirect canvas creation.
The revised implementation uses the reference rail proportions, black active states, vector tool
artwork, a width-sample strip and a compact colour grid. Native Android views are rendered in the
Robolectric graphics checks; this is implemented UI, not an HTML concept.

## Interaction contract

- The checked top-bar writing icon enables/disables writing and saves before leaving. The rail's
  collapse chevron only minimizes it. Opening controls never resizes or repaginates the reader.
- The rail contains Pen, Highlighter, two colour slots, Eraser, Lasso, Canvas, Undo, Redo and
  Options. Canvas has a visible label; Note is available from selected text. Tooltips/content descriptions name every control.
- Select a tool to use it; reselect it for settings beside the rail. Pen type, five real stroke
  samples and ten circular swatches fit into one small panel. The active colour has a ring and a
  name; selecting the secondary colour swaps slots. The available brushes are Pen, Ballpoint
  and Brush. No unsupported Scribe brush names are shown.
- Choose Canvas and tap a paragraph to add space immediately below it; drag downward to choose
  more height. A temporary positioning line follows the contact. On release, source XPointer
  resolution inserts real paragraph padding, following text reflows, and writing starts directly
  in the new paper. The selected tool and moving guide provide feedback; selecting Pen cancels placement. No
  instruction popup, paragraph picker or Apply dialog.
- A dotted outline shows canvas paper. Tap an existing canvas to write; its Options offer height,
  collapse and removal. Collapse keeps vectors; its marker expands/reopens it. Destructive deletion
  remains explicit. Blank margin contacts and stale placement events never create stored ink.
- Text selection opens a minimal action bar: Highlight, handwritten note, Look up and More. More
  opens the unchanged full KOReader selection menu. Native page writing is saved before this UI.
- The note is one flat bottom window with Handwritten/Text tabs, options and X. Its compact tools
  dock within paper, with no excerpt or nested paper outline. X saves; Text note opens the normal
  KOReader editor; Options → Discard note changes restores original handwriting.
- Popup border strokes are drawn after children, preserving all four edges. Canvas resolution uses
  the nearest source word, reveals the end of long paragraphs and retains a reusable moving-edge
  spacing handle, drawing on Notes' canonical vertical-spacing session/handle interaction.

## Integrity and limits

Keep the existing scoped native capture, save-before-handoff, background detachment, atomic stores
and failure recovery. Native placement is capture-only; it is not a second handwriting renderer.
Final native batches are saved before resizing or switching targets. The union exclusion's blank
areas also forward placement contacts, so opening a settings panel cannot swallow a page tap.

Spaces require single-page reflowable EPUB and normal LTR paragraphs outside tables/lists/floats.
Stored source anchors are resolved in CREngine; EPUB bytes and DOM structure do not change.
Entire writable rectangles must fit the viewport. Direct-page ink remains layout-fenced while canvas mutations are allowed. An Original page
handwriting action reconstructs its marked layout without moving vectors. New marks include a
geometry-only canvas recipe. A stable rendered geometry/style fingerprint recognizes an equivalent
layout after stylesheet restoration; observed old engine-hash aliases preserve existing marks. General inline wrapping, semantic movement of
page ink, expandable side-panel notes and new brush engines remain outside implemented scope.

Portable Lua and native graphics/input tests cover placement, tool switching, stale contacts,
colour slots, docking/rotation bounds, sticky rollback and save-before-resize. Reader checks pass.
Physical stylus latency, panel composition and page-turn acceptance remain with the user.

## Scribe research applied to this proposal

Sources checked 18 October 2026. Product documentation describes observable behavior, not Amazon's
internal anchor/storage implementation. Architecture suggestions above are our own deductions.

- [Kwabe Fosu, in-book writing and annotation design lead](https://kwabe.com/project/kindle-scribe):
  documents work on writing tools, lasso, copy/paste, highlights and sticky notes. His principles
  emphasize preserving reading habits and reducing annotation friction. The retrospective records
  testing gaps, fragmented execution and the value of device-native prototyping. Apply this by
  reusing the established ink path and testing complete reading-to-writing journeys on hardware.
  This is an original Scribe design case study, not proof of Colorsoft implementation details.
- [Amazon Colorsoft user guide](https://d1ergij2b6wmg5.cloudfront.net/kug/kindle_scribe_colorsoft_1st_generation/v1/en-US/html/kug.html):
  distinguishes minimized tools from hidden tools; describes two configurable colour slots;
  provides explicit canvas insertion with positioning, resizing and movement; presents side-panel
  notes as sticky notes when closed. Apply the distinctions, while retaining the user's simpler
  checked main toggle. Add two quick colour slots to avoid reopening a palette for each switch.
- [Amazon expandable-margin guide](https://digprjsurvey.amazon.co.uk/csad/help/node/TUWokwmo1I5RdrC3Mp):
  describes anchored notes, adjustable panel width, docked versus overlay views, and a panel opposite
  the writing toolbar. It explicitly limits supported writing direction. Apply anchored identities
  and distinguish a toolbar dock from a note panel; do not assume full language/layout coverage.
- [Amazon Scribe FAQ](https://www.aboutamazon.com/news/devices/kindle-scribe): states that Active
  Canvas moves text around a note and keeps notes anchored through font/layout changes. Treat that
  as a user-visible acceptance target, not something already supplied by Kalamos view keys.
- [Lee Hillman's portfolio](https://www.leehillman.com/) identifies Kindle/Scribe design leadership,
  but its case study requires authentication. No protected content was accessed or relied on.
