#!/usr/bin/env bash
# Zip the game into a .love with main.lua at the archive root.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-"$ROOT/build/game.love"}
mkdir -p "$(dirname "$OUT")"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp "$ROOT"/*.lua "$STAGE"/
cp -a "$ROOT/assets" "$STAGE/assets"
cp "$ROOT/THIRD_PARTY_LICENSES.txt" "$STAGE"/
cp "$ROOT/LICENSE" "$STAGE/LICENSE-GAME.txt"
rm -f "$OUT"
(
  cd "$STAGE"
  zip -9 -X -r "$OUT" .
)
echo "wrote $OUT"
