#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/tools/gradle.sh" :foundation:device-api:assembleDebug :devices:bigme:assembleDebug :integrations:koreader:android-bridge:assembleDebug --no-daemon "$@"
