#!/usr/bin/env bash
# bump-version.sh — set the build number (CFBundleVersion) on both app targets
# and emit release notes for a TestFlight upload.
#
# TestFlight requires every uploaded build to have a CFBundleVersion that is
# unique and monotonically increasing for a given CFBundleShortVersionString.
# In CI the simplest reliable source of a monotonic integer is the run number
# (GITHUB_RUN_NUMBER); we use it so re-running or merging repeatedly never
# collides. The marketing version (CFBundleShortVersionString) is left as-is
# and continues to be managed by hand in the Info.plist files.
#
# Usage:
#   bump-version.sh --build-number N [--notes-out PATH]
set -euo pipefail

BUILD_NUMBER=""
NOTES_OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-number) BUILD_NUMBER="$2"; shift 2 ;;
    --notes-out)    NOTES_OUT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$BUILD_NUMBER" ]]; then
  echo "ERROR: --build-number is required." >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PLISTS=("iOSApp/Info.plist" "MacApp/Info.plist")
for PLIST in "${PLISTS[@]}"; do
  if [[ ! -f "$PLIST" ]]; then
    echo "ERROR: Info.plist not found: $PLIST" >&2
    exit 1
  fi
  # PlistBuddy ships on every macOS runner; Set fails if the key is absent, so
  # fall back to Add.
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST" \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$PLIST"
  SHORT=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
  echo "==> $PLIST: version $SHORT ($BUILD_NUMBER)"
done

# Regenerate the Xcode project so the bumped Info.plist values are picked up.
if command -v xcodegen >/dev/null 2>&1; then
  echo "==> Regenerating Xcode project after version bump"
  xcodegen generate >/dev/null
fi

if [[ -n "$NOTES_OUT" ]]; then
  SHORT_VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "iOSApp/Info.plist")
  {
    echo "Version $SHORT_VER (build $BUILD_NUMBER)"
    echo ""
    if [[ -n "${GITHUB_SHA:-}" ]]; then
      echo "Commit: ${GITHUB_SHA:0:12}"
    fi
    echo ""
    echo "Recent changes:"
    # Last few commit subjects give internal testers a quick changelog.
    git log -5 --pretty='- %s' 2>/dev/null || echo "- (git history unavailable)"
  } > "$NOTES_OUT"
  echo "==> Wrote release notes to $NOTES_OUT"
fi
