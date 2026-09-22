#!/usr/bin/env bash
# Turn a routed `rb pnr` result into a hardened block's abstract set.
#
#   ./harden.sh <pnr-run-name> <top-module>
#
# e.g.
#
#   ./harden.sh demo_tiny_alu_subsys_sky130_csr_pnr     demo_tiny_alu_subsys_csr
#   ./harden.sh demo_tiny_alu_subsys_sky130_compute_pnr demo_tiny_alu_subsys_compute
#
# Writes into artefacts/<run>/abstract/ — the location rtl_buddy#95 step 1
# specifies, and inside the artefact directory so it is cleared with the rest
# of the run's outputs and is already covered by the project's gitignore:
#
#   <top>.lef                abstract LEF        (write_abstract_lef)
#   <top>.lib                Liberty model       (write_timing_model)
#   <top>.gds                layout              (copied from the run)
#   abstract.manifest.json   sha256 of all four inputs and all three outputs
#
# This is the piece rtl_buddy#95 replaces. Today it is a project-level script
# because `rb pnr` has no `harden:` key; when it does, this becomes
# `harden: true` on the run and the file goes away. Nothing here is specific to
# this example other than the two invocations above.
#
# Tool paths come from PATH or from $OPENROAD. No user paths, no absolute paths.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <pnr-run-name> <top-module>" >&2
  exit 2
fi

RUN="$1"
TOP="$2"

HERE="$(cd "$(dirname "$0")" && pwd)"
ART="$HERE/artefacts/$RUN"
OUT="$ART/abstract"

OPENROAD="${OPENROAD:-openroad}"
command -v "$OPENROAD" >/dev/null 2>&1 || {
  echo "ERROR: openroad not found on PATH (override with \$OPENROAD)" >&2
  exit 1
}

ODB="$ART/$TOP.routed.odb"
GDS="$ART/$TOP.gds"
SDC="$ART/$TOP.routed.sdc"
FLOW="$ART/pnr.tcl"

for f in "$ODB" "$GDS" "$SDC" "$FLOW"; do
  [ -s "$f" ] || {
    echo "ERROR: $f is missing or empty — run 'rb pnr $RUN --gds --gds-mode strict' first" >&2
    exit 1
  }
done

# The Liberty set the run actually used, read back out of the flow script
# rb pnr generated: `set LIBERTY <platform corner>` plus one `read_liberty`
# line per entry in the run's `lib-paths`. Taking it from there rather than
# re-deriving it from root_config.yaml keeps this script free of any knowledge
# of the platform, and guarantees the timing model is characterised against the
# same libraries the block was routed against.
LIBS="$(awk '/^set LIBERTY[ \t]/ { print $3 }
             /^read_liberty[ \t]/ && $2 !~ /^\$/ { print $2 }' "$FLOW")"
[ -n "$LIBS" ] || { echo "ERROR: no Liberty files found in $FLOW" >&2; exit 1; }

# A partial abstract directory is worse than none: a later run would read two
# fresh views and one stale one and have no way to tell. Build into a temporary
# directory and move it into place only once every output exists — the same
# all-or-nothing rule rtl_buddy#95 step 1 states for the `harden:` key.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/rb-harden.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo ">>> $RUN: writing abstract views for $TOP"
RB_HARDEN_ODB="$ODB" RB_HARDEN_TOP="$TOP" RB_HARDEN_OUT="$TMP" \
RB_HARDEN_SDC="$SDC" RB_HARDEN_LIBS="$LIBS" \
  "$OPENROAD" -no_init -exit "$HERE/harden.tcl"

cp "$GDS" "$TMP/$TOP.gds"

for f in "$TMP/$TOP.lef" "$TMP/$TOP.lib" "$TMP/$TOP.gds"; do
  [ -s "$f" ] || { echo "ERROR: $(basename "$f") was not produced" >&2; exit 1; }
done

# Fingerprint manifest. Schema mirrors the sketch in rtl_buddy#95 step 1 and
# the {path, size, sha256} shape rtl_buddy uses in export.provenance.json, so
# that when `blocks:` lands its staleness check reads the same fields. Paths
# are project-relative, because an absolute path is not a fingerprint of
# anything portable.
ROOT="$(cd "$HERE/../.." && pwd)"
python3 - "$ROOT" "$TMP" "$TOP" "$RUN" "$ART" "$OUT" <<'PY'
import hashlib, json, os, subprocess, sys, datetime

root, tmp, top, run, art, out = sys.argv[1:7]

def rel(p):
    return os.path.relpath(os.path.realpath(p), root)

def fp(p, as_path=None):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    # `as_path` is how the file will be reachable once the staging directory is
    # moved into place. Recording the staging path would make the manifest a
    # record of a directory that no longer exists.
    return {"path": rel(as_path or p), "size": os.path.getsize(p),
            "sha256": h.hexdigest()}

def maybe(p):
    return fp(p) if os.path.isfile(p) else None

try:
    orv = subprocess.run([os.environ.get("OPENROAD", "openroad"), "-version"],
                         capture_output=True, text=True, timeout=60).stdout.split("\n")[0].strip()
except Exception:
    orv = ""

manifest = {
    "schema_version": 1,
    "generator": "pnr/demo_tiny_alu_subsys_hier/harden.sh",
    "generated_at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
    "block": top,
    "pnr_run": run,
    "tool": {"name": "openroad", "version": orv},
    # Every input the hardened result depends on that this script can see from
    # the artefact directory. A `blocks:` implementation inside rb would add
    # the PDK files, the platform and corner, and the rtl_buddy version, which
    # it knows and a project-level script does not — noted in README.md as one
    # of the things the hand-wired version cannot do.
    "inputs": {
        "netlist": maybe(os.path.join(art, "%s.routed.v" % top)),
        "def": maybe(os.path.join(art, "%s.def" % top)),
        "sdc": maybe(os.path.join(art, "%s.routed.sdc" % top)),
        "odb": maybe(os.path.join(art, "%s.routed.odb" % top)),
    },
    "outputs": {
        k: fp(os.path.join(tmp, "%s.%s" % (top, k)),
              as_path=os.path.join(out, "%s.%s" % (top, k)))
        for k in ("lef", "lib", "gds")
    },
}
with open(os.path.join(tmp, "abstract.manifest.json"), "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
mv "$TMP" "$OUT"
trap - EXIT
# mktemp -d creates a 0700 directory; the abstracts are ordinary build
# outputs that anything reading the artefact tree should be able to open.
chmod -R a+rX,u+w "$OUT"

echo ">>> wrote:"
ls -1 "$OUT" | sed 's/^/      /'
