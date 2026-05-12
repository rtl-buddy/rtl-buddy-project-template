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

exec openroad -no_init -exit -log artefacts/openroad.log flow.tcl
