#!/usr/bin/env bash
# Fetches the SkyWater 130nm high-density (sky130hd) PDK views and the OpenRAM
# SRAM macro used by the hierarchical-P&R example:
#
#   pdk/sky130hd/                        standard cells — Liberty, tech+macro LEF,
#                                        cell GDS, KLayout tech/layer-properties,
#                                        OpenRCX extraction rules
#   pdk/sky130_sram/                     one compiled OpenRAM macro — LEF, GDS,
#                                        Liberty, and the behavioural Verilog model
#
# Files are not vendored — download once per checkout. `pdk/` is gitignored.
#
# Both sources are pinned to a commit so a rerun a year from now produces the
# same views the numbers in ../../pnr/demo_tiny_alu_subsys_hier/README.md were
# measured against.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PDK_DIR="$ROOT/pdk/sky130hd"
SRAM_DIR="$ROOT/pdk/sky130_sram"

# OpenROAD-flow-scripts, flow/platforms/sky130hd
ORFS_REF="3a964e13f11a4e435aac01ffa14db0a7d2853720"
ORFS_BASE="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/$ORFS_REF/flow/platforms/sky130hd"

# The OpenROAD repository's own sky130hd test views, for the two extra
# standard-cell corners the multi-corner example (the `sky130hd_mc` P&R
# platform, rtl_buddy#104 / rtl_buddy#105) signs off at: ss_n40C_1v40
# (slow-low-cold, the setup corner) and ff_n40C_1v95 (fast, the hold corner).
# ORFS' sky130hd platform ships only the tt Liberty. The ff file is ~70 MB.
OPENROAD_REF="731f8ff5a4804791a895fe594e482136fb2101bb"
OPENROAD_BASE="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD/$OPENROAD_REF/test/sky130hd"

# VLSIDA/sky130_sram_macros — OpenRAM-compiled Sky130 SRAMs (BSD-3).
# 1 kbyte, 32-bit words x 256, byte write mask, one RW port + one R port.
SRAM_REF="965df150c754fe2b3f93a0bd1f9883eb114279b2"
SRAM_NAME="sky130_sram_1kbyte_1rw1r_32x256_8"
SRAM_BASE="https://raw.githubusercontent.com/VLSIDA/sky130_sram_macros/$SRAM_REF/$SRAM_NAME"

# ORFS' sky130hd/rcx_patterns.rules is a symlink to the sky130hs file (both
# libraries share the met stack), and raw.githubusercontent.com serves a
# symlink as its target path, not its contents — so fetch the target.
ORFS_RCX="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/$ORFS_REF/flow/platforms/sky130hs/rcx_patterns.rules"

declare -a FILES=(
  "$ORFS_BASE/lib/sky130_fd_sc_hd__tt_025C_1v80.lib:$PDK_DIR/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
  "$OPENROAD_BASE/sky130_fd_sc_hd__ss_n40C_1v40.lib:$PDK_DIR/lib/sky130_fd_sc_hd__ss_n40C_1v40.lib"
  "$OPENROAD_BASE/sky130_fd_sc_hd__ff_n40C_1v95.lib:$PDK_DIR/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib"
  "$ORFS_BASE/lef/sky130_fd_sc_hd.tlef:$PDK_DIR/lef/sky130_fd_sc_hd.tlef"
  "$ORFS_BASE/lef/sky130_fd_sc_hd_merged.lef:$PDK_DIR/lef/sky130_fd_sc_hd_merged.lef"
  "$ORFS_BASE/gds/sky130_fd_sc_hd.gds:$PDK_DIR/gds/sky130_fd_sc_hd.gds"
  "$ORFS_BASE/sky130hd.lyt:$PDK_DIR/sky130hd.lyt"
  "$ORFS_BASE/sky130hd.lyp:$PDK_DIR/sky130hd.lyp"
  "$ORFS_RCX:$PDK_DIR/rcx_patterns.rules"
  "$SRAM_BASE/$SRAM_NAME.lef:$SRAM_DIR/$SRAM_NAME.lef"
  "$SRAM_BASE/$SRAM_NAME.gds:$SRAM_DIR/$SRAM_NAME.gds"
  "$SRAM_BASE/${SRAM_NAME}_TT_1p8V_25C.lib:$SRAM_DIR/${SRAM_NAME}_TT_1p8V_25C.lib"
  "$SRAM_BASE/$SRAM_NAME.v:$SRAM_DIR/$SRAM_NAME.v"
)

mkdir -p "$PDK_DIR/lib" "$PDK_DIR/lef" "$PDK_DIR/gds" "$SRAM_DIR"
for entry in "${FILES[@]}"; do
  src="${entry%:*}"
  dst="${entry##*:}"
  if [ -s "$dst" ]; then
    echo "Already present: $dst"
    continue
  fi
  echo "Downloading $(basename "$dst")"
  curl -fL "$src" -o "$dst"
done
echo "Done."
