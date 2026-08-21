#!/usr/bin/env bash
# Regenerates the APB CSR RTL from spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl
# using PeakRDL. The generated SV files (demo_tiny_alu_subsys_csr.sv,
# demo_tiny_alu_subsys_csr_pkg.sv) are committed; CI runs this script and
# `git diff --exit-code` to catch drift.
#
# Usage:
#   cd design/demo_tiny_alu_subsys && ./gen_demo_tiny_alu_subsys_csr.sh
#
# Prerequisites: `uv sync` (peakrdl + peakrdl-regblock are pinned in pyproject.toml).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RDL_FILE="${SCRIPT_DIR}/../../spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl"
OUT_DIR="${SCRIPT_DIR}"

if [[ ! -f "${RDL_FILE}" ]]; then
  echo "ERROR: RDL not found: ${RDL_FILE}" >&2
  exit 1
fi

echo "Generating CSR RTL from ${RDL_FILE} → ${OUT_DIR}"
uv run peakrdl regblock "${RDL_FILE}" \
  -o "${OUT_DIR}" \
  --cpuif apb4-flat \
  --default-reset rst_n \
  --module-name demo_tiny_alu_subsys_csr \
  --package-name demo_tiny_alu_subsys_csr_pkg

# Verilator-friendly lint waivers on the generated files
CSR_SV="${OUT_DIR}/demo_tiny_alu_subsys_csr.sv"
CSR_PKG="${OUT_DIR}/demo_tiny_alu_subsys_csr_pkg.sv"

prepend() {
  local file="$1"; shift
  local prefix="$*"
  if [[ -f "$file" ]]; then
    local tmp; tmp=$(mktemp)
    printf '%s\n' "$prefix" > "$tmp"
    cat "$file" >> "$tmp"
    mv "$tmp" "$file"
    echo "Patched $file"
  fi
}

# The timescale matches the hand-written RTL these files are compiled with
# (see design/demo_tiny_alu/demo_tiny_alu.sv): slang errors on mixed
# `timescale presence within a compilation unit (LRM 3.14.2.3), and the
# CDC lint of demo_tiny_alu_subsys_top elaborates with the slang frontend.
prepend "$CSR_SV"  '/* verilator lint_off MULTIDRIVEN */' \
                   '/* verilator lint_off GENUNNAMED */'  \
                   '/* verilator tracing_off */'
prepend "$CSR_PKG" '/* verilator tracing_off */'
# Prepended last so each ends up on its own line 1 — Verilator's
# preprocessor rejects a `timescale directive with trailing text.
prepend "$CSR_SV"  '`timescale 1ns/10ps'
prepend "$CSR_PKG" '`timescale 1ns/10ps'

echo "Done."
ls -1 "${OUT_DIR}"/*.sv 2>/dev/null
