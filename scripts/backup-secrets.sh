#!/usr/bin/env bash
# Back up ~/.zsh_api_keys to the gdrive mount. Fails gracefully if the
# mount is absent; exits 1 so callers can detect, but always prints why.
set -u

SRC="$HOME/.zsh_api_keys"
DEST_DIR="$HOME/gdrive-mount"

if [ ! -f "$SRC" ]; then
    echo "backup-secrets: $SRC not found; nothing to back up." >&2
    exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
    echo "backup-secrets: $DEST_DIR does not exist (gdrive not mounted?) - skipping." >&2
    exit 1
fi

cp -v "$SRC" "$DEST_DIR/.zsh_api_keys"
chmod 600 "$DEST_DIR/.zsh_api_keys"
echo "backup-secrets: done."
