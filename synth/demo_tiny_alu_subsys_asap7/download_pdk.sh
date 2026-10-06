#!/usr/bin/env bash
# Fetches the ASAP7 predictive 7nm PDK views used by the ASAP7 example
# (synth/demo_tiny_alu_subsys_asap7/, pnr/demo_tiny_alu_subsys_asap7/), from
# OpenROAD-flow-scripts' flow/platforms/asap7, into pdk/asap7/:
#
#   lib/NLDM/        RVT standard cells, TT corner, NLDM Liberty (the five
#                    split files ORFS lists as TC_NLDM_LIB_FILES)
#   lef/             technology LEF + RVT standard-cell LEF (1x scale)
#   gds/             RVT standard-cell GDS, for `--gds`
#   KLayout/         KLayout technology + layer properties
#   rcx_patterns.rules                  OpenRCX extraction rules
#   setRC.tcl                           per-layer wire RC  (layer-rc-tcl)
#   liberty_suppressions.tcl            STA-1212 suppression (platform-tcl)
#   openRoad/make_tracks.tcl            routing tracks      (tracks-tcl)
#   openRoad/tapcell.tcl                upstream tap/endcap script, reference
#                                       only: pnr/asap7/tapcell.tcl is the
#                                       filled-in copy the flow sources
#   openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl
#                                       upstream PDN, reference only:
#                                       pnr/asap7/pdn.tcl is the copy the
#                                       flow sources
#
# Paths under pdk/asap7/ mirror flow/platforms/asap7/ exactly, so each file can
# be traced back to upstream by its path. Files are not vendored — download
# once per checkout. `pdk/` is gitignored. About 12 MB.
#
# Provenance and licence: ASAP7 is the ASU/ARM predictive 7nm PDK and
# standard-cell library (BSD-3-Clause), as packaged by The OpenROAD Project in
# OpenROAD-flow-scripts (BSD-3-Clause). The ORFS commit is pinned so a rerun
# produces the views the numbers in ../../pnr/demo_tiny_alu_subsys_asap7/
# README.md were measured against; the two files vendored under ../../pnr/asap7/
# name the same commit in their headers.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PDK_DIR="$ROOT/pdk/asap7"

# OpenROAD-flow-scripts, flow/platforms/asap7
ORFS_REF="2aeb23bcc3b5aa925abb991c4347ce73827b8b82"
ORFS_BASE="https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/$ORFS_REF/flow/platforms/asap7"

declare -a FILES=(
  "lib/NLDM/asap7sc7p5t_AO_RVT_TT_nldm_211120.lib.gz"
  "lib/NLDM/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib.gz"
  "lib/NLDM/asap7sc7p5t_OA_RVT_TT_nldm_211120.lib.gz"
  "lib/NLDM/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib"
  "lib/NLDM/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib.gz"
  "lef/asap7_tech_1x_201209.lef"
  "lef/asap7sc7p5t_28_R_1x_220121a.lef"
  "gds/asap7sc7p5t_28_R_220121a.gds"
  "KLayout/asap7.lyt"
  "KLayout/asap7.lyp"
  "rcx_patterns.rules"
  "setRC.tcl"
  "liberty_suppressions.tcl"
  "openRoad/make_tracks.tcl"
  "openRoad/tapcell.tcl"
  "openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl"
)

for rel in "${FILES[@]}"; do
  dst="$PDK_DIR/$rel"
  if [ -s "$dst" ]; then
    echo "Already present: $dst"
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  echo "Downloading $rel"
  curl -fL "$ORFS_BASE/$rel" -o "$dst"
done
echo "Done."
