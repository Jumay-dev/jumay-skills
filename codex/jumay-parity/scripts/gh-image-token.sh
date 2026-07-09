#!/usr/bin/env bash
# Emit a repo-authorized GitHub web session token for `gh image` uploads.
#
# Why this exists: `gh image extract-token` returns the *default* browser
# session. When that session belongs to an account without access to the target
# repo, every upload fails at `step 0 (get upload token): repo page returned
# 404`. The account authorized for the repo may be signed in under a *different*
# browser profile. This helper sweeps the local Chrome profiles, decrypts each
# github.com `user_session` cookie, and prints the first one that can actually
# reach the target repo.
#
# Note: `gh image check-token` verifies only that a session is *live*, not that
# it has access to the repo — a signed-in-but-unauthorized account passes it and
# then 404s on upload. So this helper gates on an authenticated fetch of the
# repo page (200 = the account sees the repo) instead.
#
# Set GH_IMAGE_REPO to the target `owner/repo`. It is required for the access
# check; without it the helper cannot tell an authorized session from any other.
# macOS + Google Chrome. For Chromium/Brave/Edge, change SAFE_STORAGE and the
# profile base path. For Firefox/Zen, use the vro-upload cookie path instead.
#
# Usage:
#   TOKEN=$(scripts/gh-image-token.sh) || exit 1
#   GH_SESSION_TOKEN="$TOKEN" gh image --repo "$GH_IMAGE_REPO" <png>...
set -euo pipefail

REPO="${GH_IMAGE_REPO:-}"
if [ -z "$REPO" ]; then
  echo "gh-image-token: set GH_IMAGE_REPO=owner/repo (needed to verify repo access)" >&2
  exit 2
fi
SAFE_STORAGE="Chrome Safe Storage"
CHROME="$HOME/Library/Application Support/Google/Chrome"

key=$(security find-generic-password -w -s "$SAFE_STORAGE" 2>/dev/null) || {
  echo "gh-image-token: cannot read '$SAFE_STORAGE' from keychain" >&2; exit 1; }
key_hex=$(python3 - "$key" <<'PY'
import sys, hashlib
print(hashlib.pbkdf2_hmac('sha1', sys.argv[1].encode(), b'saltysalt', 1003, 16).hex())
PY
)
iv_hex=$(python3 -c "print((' ' * 16).encode().hex())")

# Sweep every Chrome profile; emit the first session gh image accepts.
profiles=("Default")
while IFS= read -r p; do profiles+=("$p"); done < <(ls "$CHROME" 2>/dev/null | grep -E '^Profile [0-9]+$' || true)

seen=""
for profile in "${profiles[@]}"; do
  case " $seen " in *" $profile "*) continue;; esac
  seen="$seen $profile"
  db="$CHROME/$profile/Cookies"
  [ -f "$db" ] || continue
  tmp="/tmp/gh-image-cookies-${profile// /-}.sqlite"
  cp "$db" "$tmp" 2>/dev/null || continue
  hex=$(sqlite3 "$tmp" "select hex(substr(encrypted_value,4)) from cookies where host_key='github.com' and name='user_session' limit 1;" 2>/dev/null || true)
  rm -f "$tmp"
  [ -n "$hex" ] || continue
  # AES-128-CBC, IV = 16 spaces; drop the 32-byte SHA256 domain-bind prefix.
  token=$(printf "%s" "$hex" | xxd -r -p | openssl enc -d -aes-128-cbc -K "$key_hex" -iv "$iv_hex" 2>/dev/null | tail -c +33 || true)
  [ -n "$token" ] || continue
  # Gate on real repo access, not mere session liveness: an authenticated GET of
  # the repo page returns 200 for an authorized account, 404 for one without
  # access. This is the same access boundary gh image's upload-token step hits.
  code=$(curl -s -o /dev/null -w '%{http_code}' \
    -H "Cookie: user_session=$token; logged_in=yes" \
    "https://github.com/$REPO" || true)
  if [ "$code" = "200" ]; then
    printf '%s' "$token"
    exit 0
  fi
done

echo "gh-image-token: no Chrome profile has a live github.com session with access to $REPO" >&2
echo "Fix: sign into github.com as a repo-authorized account in Chrome, then retry." >&2
exit 1
