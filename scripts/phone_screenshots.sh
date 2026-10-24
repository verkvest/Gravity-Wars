#!/usr/bin/env bash
# Capture the menu and a live shot at a phone landscape size (2340x1080).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR=${1:-"$ROOT/build/screenshots"}
mkdir -p "$WORKDIR"
cd "$WORKDIR"
if [ ! -x squashfs-root/bin/love ]; then
  curl -fsSL --retry 5 -o love.AppImage \
    https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage
  chmod +x love.AppImage
  ./love.AppImage --appimage-extract
fi
export XDG_DATA_HOME="$WORKDIR/xdg"
rm -rf "$XDG_DATA_HOME"
mkdir -p "$XDG_DATA_HOME"
export CINDARC_SCREENSHOT=1
export LD_LIBRARY_PATH="$WORKDIR/squashfs-root/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
xvfb-run -a "$WORKDIR/squashfs-root/bin/love" "$ROOT"
OUT="$ROOT/build/phone-screenshots"
mkdir -p "$OUT"
cp "$XDG_DATA_HOME/love/cindarc/menu.png" "$OUT/menu.png"
cp "$XDG_DATA_HOME/love/cindarc/gameplay.png" "$OUT/gameplay.png"
echo "screenshots in $OUT"
