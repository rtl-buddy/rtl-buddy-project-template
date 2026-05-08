#!/usr/bin/env bash
# Regenerates the APB CSR RTL from spec/alu_accel/alu_accel_csr.rdl
# using PeakRDL. The generated SV files (alu_accel_csr.sv,
# alu_accel_csr_pkg.sv) are committed; CI runs this script and
# `git diff --exit-code` to catch drift.
#
# Usage:
#   cd design/alu_accel && ./gen_alu_accel_csr.sh
#
# Prerequisites: `uv sync` (peakrdl + peakrdl-regblock are pinned in pyproject.toml).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RDL_FILE="${SCRIPT_DIR}/../../spec/alu_accel/alu_accel_csr.rdl"
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
  --module-name alu_accel_csr \
  --package-name alu_accel_csr_pkg

# Verilator-friendly lint waivers on the generated files
CSR_SV="${OUT_DIR}/alu_accel_csr.sv"
CSR_PKG="${OUT_DIR}/alu_accel_csr_pkg.sv"

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

prepend "$CSR_SV"  '/* verilator lint_off MULTIDRIVEN */' \
                   '/* verilator lint_off GENUNNAMED */'  \
                   '/* verilator tracing_off */'
prepend "$CSR_PKG" '/* verilator tracing_off */'

echo "Done."
ls -1 "${OUT_DIR}"/*.sv 2>/dev/null
