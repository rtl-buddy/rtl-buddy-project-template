#!/usr/bin/env bash
# Writes the tt, ss and ff Liberty of the OpenRAM SRAM that the multi-corner
# demo (pnr.yaml in this directory) maps to its corners. They are demo files
# derived from the macro's one Liberty, the TT 1.8 V 25 C file that
# synth/demo_tiny_alu_subsys_hier/download_pdk.sh fetches. They are not
# characterised data.
#
# Every copy renames the library and raises the 0.04 ns max_transition of the
# address and write-mask pins to 0.5 ns, the library's default_max_transition.
# ss and ff also multiply the clock-to-output tables (cell_rise and cell_fall
# of dout0 and dout1) by 2 and 0.7. Nothing else changes:
#
#   tt  x1.0   ..._TT_derived.lib
#   ss  x2.0   ..._SS_derived.lib
#   ff  x0.7   ..._FF_derived.lib
#
# The files go to pdk/sky130_sram/, beside the TT file. pdk/ is gitignored.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRAM_DIR="$ROOT/pdk/sky130_sram"
SRAM_NAME="sky130_sram_1kbyte_1rw1r_32x256_8"
TT_LIB="$SRAM_DIR/${SRAM_NAME}_TT_1p8V_25C.lib"

if [ ! -s "$TT_LIB" ]; then
  echo "Missing $TT_LIB; run synth/demo_tiny_alu_subsys_hier/download_pdk.sh first." >&2
  exit 1
fi

derive() {
  local corner=$1 factor=$2
  local out="$SRAM_DIR/${SRAM_NAME}_${corner}_derived.lib"
  awk -v factor="$factor" -v corner="$corner" -v name="$SRAM_NAME" '
    NR == 1 {
      print "/* Derived from " name "_TT_1p8V_25C.lib for the template'"'"'s multi-corner"
      print "   demo: pin max_transition 0.5 ns" (factor == 1 ? "" : ", clock-to-output tables x" factor) "."
      print "   Not characterised data. */"
      sub(/_TT_1p8V_25C_lib/, "_" corner "_derived_lib")
    }
    /cell_(rise|fall)\(/ { table = 1 }
    table && /"/ {
      line = $0
      out = ""
      while (match(line, /-?[0-9]+\.[0-9]+/)) {
        out = out substr(line, 1, RSTART - 1) sprintf("%.3f", substr(line, RSTART, RLENGTH) * factor)
        line = substr(line, RSTART + RLENGTH)
      }
      $0 = out line
    }
    table && /}/ { table = 0 }
    /max_transition *:/ && !/default_max_transition/ {
      match($0, /[0-9]+\.[0-9]+/)
      $0 = substr($0, 1, RSTART - 1) "0.5" substr($0, RSTART + RLENGTH)
    }
    { print }
  ' "$TT_LIB" > "$out"
  echo "Wrote $out"
}

derive TT 1.0
derive SS 2.0
derive FF 0.7
