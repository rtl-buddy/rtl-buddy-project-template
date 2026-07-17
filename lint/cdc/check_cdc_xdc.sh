#!/usr/bin/env bash
#
# demo_cdc_open — scoped CDC constraint generate -> audit loop.
#
# Demonstrates the rtl_buddy CDC constraint loop end to end:
#   1. GENERATE  `rb cdc --emit-constraints --scoped` derives the scoped,
#      per-synchronizer timing exceptions from the verified crossing set.
#   2. FRESHNESS the regenerated set must match the committed
#      fpga/demo_cdc_open/demo_cdc_open_cdc_scoped.xdc (regenerate when the
#      RTL changes; the file is a generated artefact, not hand-authored).
#   3. AUDIT     `rb cdc --check-xdc` confirms the top + scoped XDC together
#      cover every crossing with zero over-waive.
#
# Gated: on a checkout whose rtl_buddy predates --emit-constraints /
# --check-xdc, the script prints SKIP and exits 0 (so it stays green in a
# regression that a fresh clone runs). Override the driver with e.g.
# `RB="uv run rb" ./check_cdc_xdc.sh` (CI) — it defaults to `rb`.
set -euo pipefail

RB="${RB:-rb}"
here="$(cd "$(dirname "$0")" && pwd)"
fpga_dir="$here/../../fpga/demo_cdc_open"
top_xdc="$fpga_dir/demo_cdc_open.xdc"
scoped_xdc="$fpga_dir/demo_cdc_open_cdc_scoped.xdc"

cd "$here"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- feature gate --------------------------------------------------------
# Redirect --help to a file: the Rich help renderer wraps option names
# unpredictably when writing to a pipe, but is stable to a file.
$RB cdc --help > "$tmp/help.txt" 2>&1 || true
if ! grep -q -- '--emit-constraints' "$tmp/help.txt"; then
  echo "SKIP: this rtl_buddy has no 'rb cdc --emit-constraints' (upgrade to use the CDC constraint loop)"
  exit 0
fi

# --- 1/3 generate --------------------------------------------------------
echo "[1/3] generate scoped CDC exceptions (rb cdc --emit-constraints --scoped)"
$RB cdc -c cdc.yaml demo_cdc_open_lint --emit-constraints --format xdc --scoped \
  -o "$tmp/scoped.xdc"

# --- 2/3 freshness -------------------------------------------------------
echo "[2/3] check committed scoped XDC is up to date"
if ! diff -u "$scoped_xdc" "$tmp/scoped.xdc"; then
  echo "FAIL: $scoped_xdc is stale — regenerate it:"
  echo "      cd lint/cdc && rb cdc -c cdc.yaml demo_cdc_open_lint \\"
  echo "        --emit-constraints --format xdc --scoped -o \\"
  echo "        ../../fpga/demo_cdc_open/demo_cdc_open_cdc_scoped.xdc"
  exit 1
fi

# --- 3/3 audit -----------------------------------------------------------
echo "[3/3] audit top + scoped XDC against the verified crossing set"
cat "$top_xdc" "$scoped_xdc" > "$tmp/combined.xdc"
$RB --machine cdc -c cdc.yaml demo_cdc_open_lint --check-xdc "$tmp/combined.xdc" \
  > "$tmp/audit.json"
python3 - "$tmp/audit.json" <<'PY'
import json, sys

d = json.load(open(sys.argv[1]))
p = d.get("payload", {})
blockers = p.get("blockers", 0)
findings = p.get("findings", [])
print(f"      audit: exit={d.get('exit_code')} blockers={blockers} findings={len(findings)}")
for f in findings:
    print(f"        - {f['severity']}/{f['kind']}: {f['message']}")
sys.exit(1 if blockers else 0)
PY

echo "OK: scoped XDC fresh; top + scoped audit clean (full coverage, zero over-waive)"
