#!/usr/bin/env bash
# Render a PNG of the routed GDS using KLayout headlessly.
# Output: pnr/demo_tiny_alu_subsys/artefacts/<design>.png
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DESIGN="demo_tiny_alu_subsys_synth_top"

GDS_IN="$SCRIPT_DIR/artefacts/${DESIGN}.gds"
PNG_OUT="$SCRIPT_DIR/artefacts/${DESIGN}.png"
LYP="$REPO_ROOT/pdk/nangate45/FreePDK45.lyp"
GDS2PNG="$REPO_ROOT/tools/openroad/gds2png.py"

if [ ! -s "$GDS_IN" ]; then
  echo "GDS not found: $GDS_IN" >&2
  echo "Run ./pnr/demo_tiny_alu_subsys/run.sh first." >&2
  exit 1
fi

KLAYOUT_BIN="${KLAYOUT_BIN:-}"
if [ -z "$KLAYOUT_BIN" ] && command -v klayout >/dev/null 2>&1; then
  KLAYOUT_BIN="$(command -v klayout)"
fi
if [ -z "$KLAYOUT_BIN" ] && [ -x "/Applications/KLayout/klayout.app/Contents/MacOS/klayout" ]; then
  KLAYOUT_BIN="/Applications/KLayout/klayout.app/Contents/MacOS/klayout"
fi
if [ -z "$KLAYOUT_BIN" ]; then
  echo "KLayout not found. brew install --cask klayout" >&2
  exit 1
fi

WIDTH="${WIDTH:-2048}"
HEIGHT="${HEIGHT:-2048}"

echo ">>> Rendering $GDS_IN -> $PNG_OUT (${WIDTH}x${HEIGHT})"
"$KLAYOUT_BIN" -zz -nc \
  -rd in_gds="$GDS_IN" \
  -rd lyp_file="$LYP" \
  -rd out_png="$PNG_OUT" \
  -rd width="$WIDTH" \
  -rd height="$HEIGHT" \
  -r "$GDS2PNG"

if [ -s "$PNG_OUT" ]; then
  echo ">>> Wrote $PNG_OUT ($(du -h "$PNG_OUT" | cut -f1))"
else
  echo "PNG render failed — $PNG_OUT missing." >&2
  exit 1
fi
