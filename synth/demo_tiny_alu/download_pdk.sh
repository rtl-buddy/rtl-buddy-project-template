#!/usr/bin/env bash
# Fetches the Nangate45 typical-corner Liberty file used by the
# `demo_tiny_alu_synth_nangate45` synth run. The PDK is intentionally not
# vendored — download once per checkout to exercise the tech-mapped
# flow.
set -euo pipefail

PDK_DIR="$(cd "$(dirname "$0")/../.." && pwd)/pdk/nangate45/lib"
LIB="$PDK_DIR/NangateOpenCellLibrary_typical.lib"
URL="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/master/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib"

mkdir -p "$PDK_DIR"
if [ -s "$LIB" ]; then
  echo "Liberty already present at $LIB"
  exit 0
fi
echo "Downloading Nangate45 Liberty to $LIB"
curl -fL "$URL" -o "$LIB"
echo "Done."
