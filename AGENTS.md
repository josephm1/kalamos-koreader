# Agent guide

Read README.md, HANDOVER.md and docs/devices/bigme/INK-WRITING-GUIDE.md first.

- Reader Lua/UI/persistence: integrations/koreader/kalamos.koplugin.
- Independent Android excerpt sharing: integrations/koreader-toc-share.
- Engine/launcher changes: integrations/koreader/engine and patches.
- Neutral contracts: foundation/device-api.
- Bigme firmware/e-ink policy: devices/bigme.
- Native reader lifecycle/bridge: integrations/koreader/android-bridge.

Keep this build independent of sibling checkouts. Do not restore retired companion apps, AI mapper routes, private data or certificates. Preserve book IDs, handwriting storage paths and legacy saved vectors. User performs physical-device testing; automated tests/builds do not establish panel acceptance.
