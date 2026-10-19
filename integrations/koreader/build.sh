#!/usr/bin/env bash
set -euo pipefail

check_only=false
if [[ "${1:-}" == --check-only ]]; then check_only=true; shift; fi
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [--check-only] /path/to/koreader" >&2
  exit 2
fi
integration_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$integration_dir/../.." && pwd)"
koreader_dir="$(cd "$1" && pwd)"
launcher_dir="$koreader_dir/platform/android/luajit-launcher"
if [[ ! -f "$koreader_dir/Makefile" || ! -f "$launcher_dir/app/build.gradle" || ! -f "$koreader_dir/base/ffi/input_android.lua" ]]; then
  echo "Expected a KOReader checkout with the base and Android launcher submodules initialized." >&2
  exit 2
fi
if grep -Eq 'kalamosLaunch|kalamosPendingPlayReading' "$launcher_dir/app/src/main/java/org/koreader/launcher/MainActivity.kt"; then
  echo "Obsolete companion bridge detected; prepare a clean KOReader checkout." >&2
  exit 1
fi
if grep -Fq 'ext.minSdk = 29' "$launcher_dir/build.gradle"; then
  echo "Old global minimum-SDK patch detected; prepare a clean checkout for optional native ink." >&2
  exit 1
fi
if grep -Fq 'koreader-crash.log' "$launcher_dir/app/src/main/java/org/koreader/launcher/MainApp.kt" \
  && ! grep -Fq 'writeLogToFile(crash_report_path, !BuildConfig.DEBUG)' "$launcher_dir/app/src/main/java/org/koreader/launcher/MainApp.kt"; then
  echo "Old always-on crash diagnostics detected; prepare a clean checkout." >&2
  exit 1
fi
if grep -Fq 'KALAMOS_ASSET_REVISION' "$koreader_dir/make/android.mk" \
  && ! grep -Fq 'platform/android/luajit-launcher/app/libs/kalamos-*.aar' "$koreader_dir/make/android.mk"; then
  echo "Old Lua-only asset revision detected; prepare a clean checkout for native revision tracking." >&2
  exit 1
fi

# Check every complete patch (including added adapter files) before compiling/copying anything.
# A marker string alone cannot establish that a previously patched checkout is compatible.
pending_repositories=()
pending_patches=()
check_patch() {
  local checkout="$1" patch="$integration_dir/patches/$2"
  if git -C "$checkout" apply --reverse --check "$patch" 2>/dev/null; then
    echo "Already applied: $2"
  elif git -C "$checkout" apply --check "$patch"; then
    pending_repositories+=("$checkout")
    pending_patches+=("$patch")
    echo "Applies cleanly: $2"
  else
    echo "Conflicting or partial patch: $2. Use the pinned clean checkout or rebase explicitly." >&2
    exit 1
  fi
}
check_patch "$koreader_dir/base" handwriting/engine-writing-space.patch
check_patch "$koreader_dir" handwriting/reader-writing-actions.patch
check_patch "$launcher_dir" handwriting/launcher-optional-native-build.patch
check_patch "$launcher_dir" handwriting/launcher-kalamos-bridge.patch
check_patch "$launcher_dir" android-diagnostics/launcher-readable-crash-report.patch
check_patch "$koreader_dir/base" android-input/android-native-motion-filter.patch
check_patch "$koreader_dir" private-build/android-kalamos-asset-revision.patch
if $check_only; then
  echo "All reader/native patches verified; no build or checkout mutation performed."
  exit 0
fi

# KOReader parses git describe at startup; source-only shallow review branches need release history
# fetched before a complete reader distribution can be packaged with a valid version.
revision="$(git -C "$koreader_dir" describe HEAD 2>/dev/null || true)"
if [[ ! "$revision" =~ ^v[0-9]{4}\.[0-9]{2} ]]; then
  echo "KOReader needs a reachable release tag; fetch its history and tags before building." >&2
  exit 1
fi
"$repo_root/tools/gradle.sh" \
  :foundation:device-api:assembleDebug \
  :devices:bigme:assembleDebug \
  :integrations:koreader:android-bridge:assembleDebug \
  -Pkalamos.device=bigme --no-daemon
for index in "${!pending_patches[@]}"; do
  git -C "${pending_repositories[$index]}" apply "${pending_patches[$index]}"
done
cp "$integration_dir/engine/writingspace.inc" "$koreader_dir/base/writingspace.inc"
mkdir -p "$launcher_dir/app/libs"
cp "$repo_root/foundation/device-api/build/outputs/aar/device-api-debug.aar" "$launcher_dir/app/libs/kalamos-device-api.aar"
cp "$repo_root/devices/bigme/build/outputs/aar/bigme-debug.aar" "$launcher_dir/app/libs/kalamos-bigme.aar"
cp "$repo_root/integrations/koreader/android-bridge/build/outputs/aar/android-bridge-debug.aar" "$launcher_dir/app/libs/kalamos-koreader-bridge.aar"
rm -rf "$koreader_dir/plugins/kalamos.koplugin"
cp -a "$integration_dir/kalamos.koplugin" "$koreader_dir/plugins/kalamos.koplugin"
# The private extraction revision must change for engine/menu/icon-only changes too.
writing_revision="$(sha256sum "$integration_dir/engine/writingspace.inc" \
  "$integration_dir/patches/handwriting/engine-writing-space.patch" \
  "$integration_dir/patches/handwriting/reader-writing-actions.patch" \
  "$integration_dir"/kalamos.koplugin/resources/icons/*.svg | sha256sum | cut -c1-16)"
printf 'return "%s"\n' "$writing_revision" > "$koreader_dir/plugins/kalamos.koplugin/writing-revision.lua"
cp "$integration_dir"/kalamos.koplugin/resources/icons/kalamos*.svg "$koreader_dir/resources/icons/mdlight/"
echo "Kalamos plugin and optional bridge prepared in $koreader_dir"
echo "Normal build: GRADLE_FLAGS=-PkalamosInk=true ./kodev build android-arm64"
echo "Debug build:  GRADLE_FLAGS=-PkalamosInk=true ./kodev build android-arm64 --debug"
echo "Then package the APK: GRADLE_FLAGS=-PkalamosInk=true make TARGET=android-arm64 update"
echo "For a debug APK use:  GRADLE_FLAGS=-PkalamosInk=true make TARGET=android-arm64 KODEBUG=1 update"
echo "Without that property the launcher retains stock dependencies and SDK floor."
