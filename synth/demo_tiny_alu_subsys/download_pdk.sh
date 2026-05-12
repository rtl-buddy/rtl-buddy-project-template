#!/usr/bin/env bash
# Fetches Nangate45 PDK files used by the demo_tiny_alu_subsys flow:
#   - Liberty (.lib) for tech-mapped Yosys synthesis
#   - Tech LEF + macro LEF for OpenROAD P&R (pnr/demo_tiny_alu_subsys/)
# Files are not vendored — download once per checkout.
set -euo pipefail

PDK_DIR="$(cd "$(dirname "$0")/../.." && pwd)/pdk/nangate45"
LIB_DIR="$PDK_DIR/lib"
LEF_DIR="$PDK_DIR/lef"

BASE="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/master/flow/platforms/nangate45"

declare -a FILES=(
  "lib/NangateOpenCellLibrary_typical.lib:$LIB_DIR/NangateOpenCellLibrary_typical.lib"
  "lef/NangateOpenCellLibrary.tech.lef:$LEF_DIR/NangateOpenCellLibrary.tech.lef"
  "lef/NangateOpenCellLibrary.macro.mod.lef:$LEF_DIR/NangateOpenCellLibrary.macro.mod.lef"
  "gds/NangateOpenCellLibrary.gds:$PDK_DIR/gds/NangateOpenCellLibrary.gds"
)

mkdir -p "$LIB_DIR" "$LEF_DIR" "$PDK_DIR/gds"
for entry in "${FILES[@]}"; do
  src="${entry%%:*}"
  dst="${entry##*:}"
  if [ -s "$dst" ]; then
    echo "Already present: $dst"
    continue
  fi
  echo "Downloading $src -> $dst"
  curl -fL "$BASE/$src" -o "$dst"
done
echo "Done."
