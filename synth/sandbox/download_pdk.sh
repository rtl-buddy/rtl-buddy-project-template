#!/usr/bin/env bash
# Fetches the Nangate45 Liberty + LEF assets used by the sandbox
# tech-mapped synthesis runs. The PDK is intentionally not vendored —
# download once per checkout to exercise the Yosys and OpenROAD flows.
set -euo pipefail

PDK_ROOT="$(cd "$(dirname "$0")/../.." && pwd)/pdk/nangate45"
LIB_DIR="$PDK_ROOT/lib"
LEF_DIR="$PDK_ROOT/lef"
LIB="$LIB_DIR/NangateOpenCellLibrary_typical.lib"
LEF="$LEF_DIR/NangateOpenCellLibrary.macro.mod.lef"
LIB_URL="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/master/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib"
LEF_URL="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/master/flow/platforms/nangate45/lef/NangateOpenCellLibrary.macro.mod.lef"

mkdir -p "$LIB_DIR" "$LEF_DIR"

if [ ! -s "$LIB" ]; then
  echo "Downloading Nangate45 Liberty to $LIB"
  curl -fL "$LIB_URL" -o "$LIB"
else
  echo "Liberty already present at $LIB"
fi

if [ ! -s "$LEF" ]; then
  echo "Downloading Nangate45 LEF to $LEF"
  curl -fL "$LEF_URL" -o "$LEF"
else
  echo "LEF already present at $LEF"
fi

echo "Done."
