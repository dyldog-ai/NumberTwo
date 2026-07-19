#!/usr/bin/env bash
# testflight-upload.sh — upload an exported iOS .ipa / macOS .pkg to TestFlight.
#
# Called by .github/workflows/ci-build.yml after scripts/ci-build.sh has produced
# a signed, App Store-method export under build/export/<platform>/. Authentication
# uses an App Store Connect API key (issuer id + key id + .p8), which is the
# credential type Apple recommends for CI (no Apple ID / 2FA prompts).
#
# Once uploaded, the build is processed by Apple and — because the app has an
# internal-testing group configured in App Store Connect — is automatically made
# available to internal testers, typically within a few minutes to ~30 min.
#
# Usage:
#   testflight-upload.sh --platform ios|macos [--notes-file PATH]
#
# Required environment (provided by the workflow from repo secrets):
#   ASC_KEY_ID       App Store Connect API key id      (secrets.APP_STORE_CONNECT_API_KEY_ID)
#   ASC_ISSUER_ID    App Store Connect API issuer id   (secrets.APP_STORE_CONNECT_API_ISSUER_ID)
#   ASC_KEY_P8_BASE64  base64 of the AuthKey_XXXX.p8   (secrets.APP_STORE_CONNECT_API_KEY_BASE64)
set -euo pipefail

PLATFORM=""
NOTES_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)   PLATFORM="$2"; shift 2 ;;
    --notes-file) NOTES_FILE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "macos" ]]; then
  echo "ERROR: --platform must be 'ios' or 'macos'." >&2
  exit 2
fi

# Fail loudly if the credentials are missing — this script must only run when
# TestFlight upload is actually expected to happen.
: "${ASC_KEY_ID:?ASC_KEY_ID is required}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID is required}"
: "${ASC_KEY_P8_BASE64:?ASC_KEY_P8_BASE64 is required}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EXPORT_PATH="build/export/$PLATFORM"
if [[ ! -d "$EXPORT_PATH" ]]; then
  echo "ERROR: export directory not found: $EXPORT_PATH (was the signed build exported?)" >&2
  exit 1
fi

# Locate the uploadable artifact. iOS exports a .ipa; macOS app-store exports a .pkg.
if [[ "$PLATFORM" == "ios" ]]; then
  UPLOAD_TYPE="ios"
  ARTIFACT=$(find "$EXPORT_PATH" -maxdepth 2 -name '*.ipa' | head -n 1)
else
  UPLOAD_TYPE="macos"
  ARTIFACT=$(find "$EXPORT_PATH" -maxdepth 2 -name '*.pkg' | head -n 1)
fi

if [[ -z "$ARTIFACT" ]]; then
  echo "ERROR: no uploadable artifact (.ipa/.pkg) found under $EXPORT_PATH" >&2
  find "$EXPORT_PATH" -maxdepth 2 -type f >&2 || true
  exit 1
fi
echo "==> Uploading artifact: $ARTIFACT"

# altool discovers the private key via ~/.appstoreconnect/private_keys or the
# --apiKey/--apiIssuer flags; we materialise the .p8 where altool looks for it.
KEY_DIR="$HOME/.appstoreconnect/private_keys"
mkdir -p "$KEY_DIR"
KEY_FILE="$KEY_DIR/AuthKey_${ASC_KEY_ID}.p8"
echo "$ASC_KEY_P8_BASE64" | base64 --decode > "$KEY_FILE"
chmod 600 "$KEY_FILE"
# Ensure the key material is scrubbed even if the upload fails.
cleanup() { rm -f "$KEY_FILE"; }
trap cleanup EXIT

if [[ -n "$NOTES_FILE" && -f "$NOTES_FILE" ]]; then
  echo "==> Release notes for this build:"
  sed 's/^/    /' "$NOTES_FILE"
  echo "    (Internal testers get the build automatically; 'What to Test' notes"
  echo "     for internal groups are informational and set in App Store Connect.)"
fi

echo "==> Validating $UPLOAD_TYPE build with App Store Connect"
xcrun altool --validate-app \
  -f "$ARTIFACT" \
  --type "$UPLOAD_TYPE" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"

echo "==> Uploading $UPLOAD_TYPE build to TestFlight"
xcrun altool --upload-app \
  -f "$ARTIFACT" \
  --type "$UPLOAD_TYPE" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"

echo "==> Upload complete. Apple is now processing the build; it will appear for"
echo "    internal testers once processing finishes (usually well under 30 min)."
