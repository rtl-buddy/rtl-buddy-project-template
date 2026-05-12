#!/usr/bin/env bash
# Drive the OpenROAD flow for demo_tiny_alu_subsys end-to-end.
#
# Prerequisites:
#   1. `openroad` on PATH (locally installed).
#   2. Synthesized netlist:
#        rb synth demo_tiny_alu_subsys_synth_nangate45 \
#          -c synth/demo_tiny_alu_subsys/synth.yaml
#   3. PDK files fetched:
#        synth/demo_tiny_alu_subsys/download_pdk.sh
#
# Outputs land in pnr/demo_tiny_alu_subsys/artefacts/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NETLIST="$REPO_ROOT/synth/demo_tiny_alu_subsys/artefacts/demo_tiny_alu_subsys_synth_nangate45/synth_netlist.v"
LIB="$REPO_ROOT/pdk/nangate45/lib/NangateOpenCellLibrary_typical.lib"
TECH_LEF="$REPO_ROOT/pdk/nangate45/lef/NangateOpenCellLibrary.tech.lef"

for f in "$NETLIST" "$LIB" "$TECH_LEF"; do
  if [ ! -s "$f" ]; then
    echo "Missing prerequisite: $f" >&2
    echo "See header of $0 for how to produce it." >&2
    exit 1
  fi
done

cd "$SCRIPT_DIR"
mkdir -p artefacts

# Workaround for a known macOS issue where OpenROAD links libomp twice
# (once via the binary, once via a backend library). Unset to debug.
export KMP_DUPLICATE_LIB_OK="${KMP_DUPLICATE_LIB_OK:-TRUE}"

openroad -no_init -exit -log artefacts/openroad.log flow.tcl

# GDS streamout via KLayout — upstream OpenROAD doesn't bind write_gds
# at the Tcl level. Skip silently if klayout isn't installed; the
# routed DEF is the load-bearing artefact for the demo.
DESIGN="demo_tiny_alu_subsys_synth_top"
DEF_IN="$SCRIPT_DIR/artefacts/${DESIGN}.def"
GDS_OUT="$SCRIPT_DIR/artefacts/${DESIGN}.gds"
PDK="$REPO_ROOT/pdk/nangate45"
TECH_LYT="$PDK/FreePDK45.lyt"
MACRO_GDS="$PDK/gds/NangateOpenCellLibrary.gds"
DEF2STREAM="$REPO_ROOT/tools/openroad/def2stream.py"

if [ ! -s "$DEF_IN" ]; then
  echo "Routed DEF missing — OpenROAD stage failed?" >&2
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
  echo ">>> KLayout not found; skipping GDS streamout."
  echo "    Install via 'brew install --cask klayout' to enable."
  exit 0
fi

echo ">>> GDS streamout via $KLAYOUT_BIN"
"$KLAYOUT_BIN" -zz -nc \
  -rd design_name="$DESIGN" \
  -rd in_def="$DEF_IN" \
  -rd in_files="$MACRO_GDS" \
  -rd tech_file="$TECH_LYT" \
  -rd layer_map="" \
  -rd seal_file="" \
  -rd out_file="$GDS_OUT" \
  -r "$DEF2STREAM"

if [ -s "$GDS_OUT" ]; then
  echo ">>> Wrote $GDS_OUT ($(du -h "$GDS_OUT" | cut -f1))"
else
  echo "GDS streamout failed — $GDS_OUT missing." >&2
  exit 1
fi
