# Upstream attribution and licensing

Kalamos for KOReader is an independent adaptation of **[KOReader](https://github.com/koreader/koreader)**
by the KOReader project and its contributors. The reader, rendering engine, Android launcher and
long-running community work make this integration possible. Original copyright notices remain
with their authors; this repository does not claim authorship of the upstream projects or endorsement.

| Component | Upstream and authors | Licence / local text |
| --- | --- | --- |
| KOReader frontend | [KOReader contributors](https://github.com/koreader/koreader) | AGPL-3.0-or-later; [COPYING](COPYING) |
| KOReader base integration | [koreader-base contributors](https://github.com/koreader/koreader-base) | AGPL-3.0-or-later for the base project; individual bundled libraries retain their own terms |
| Android LuaJIT launcher and patches | [KOReader launcher contributors](https://github.com/koreader/android-luajit-launcher), including Hans-Werner Hilse | MIT; [full notice](LICENSES/KOReader-launcher-MIT.txt) |
| JNI scaffolding used in androidbridge.lua | [Android App Launcher for KOReader](https://github.com/omer-faruq/android-app-launcher.koplugin), Alexander Mikhailian | MIT; [full notice](integrations/koreader/kalamos.koplugin/LICENSES/Android-App-Launcher-MIT.txt) |
| Kalamos handwriting plugins and native reader bridge | Kalamos contributors | AGPL-3.0-or-later; licences in each plugin/module |
| Ink contracts and Bigme provider | [InkSDK, Ed Wei (imedwei) and contributors](https://github.com/imedwei/inksdk), adapted by Kalamos | GPL-3.0-only for this adaptation; [scope and credits](docs/licensing/INKSDK.md), [GPL text](LICENSES/GPL-3.0.txt) |
| Generic Android ink provider | Kalamos contributors | GPL-3.0-only; [module licence](devices/standard/LICENSE) |
| AndroidHiddenApiBypass / AndroidX / Gradle wrapper | LSPosed / Android Open Source Project / Gradle contributors | Apache-2.0; [text](LICENSES/Apache-2.0.txt); retain their component notices |

Exact KOReader, base and launcher source revisions are recorded in
[integrations/review/upstream.lock.json](integrations/review/upstream.lock.json).
The root AGPL text covers the reader integration; it does not replace the MIT, GPL or other
component licences. GPLv3 section 13 permits combination with AGPLv3 while preserving the
licences of the respective parts. Vendor firmware remains proprietary and is not distributed here.

This repository contains modified integration sources and patches; obtain the pinned upstream
sources and their submodules to build the complete reader. When distributing a combined binary,
provide corresponding source for the actual reader, engine, launcher, plugins and ink modules,
including modifications and build scripts, and preserve all applicable notices. Upstream dependency
licences and source/build requirements are not replaced by this summary. The JNI MIT notice is also
included in the plugin's THIRD_PARTY_NOTICES.md so it survives LICENSE-filename packaging exclusions.
