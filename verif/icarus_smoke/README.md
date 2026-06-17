# icarus_smoke

A minimal end-to-end smoke suite for the **Icarus Verilog** simulator backend.

The design (`design/icarus_smoke/counter.sv`) and testbench (`tb_counter.sv`)
are deliberately plain SV-2012 — no classes, SVA, or covergroups — so the same
suite compiles and passes on **both Verilator and Icarus** (Icarus 12 does not
support those constructs; see the rtl_buddy capability matrix).

## Selecting the simulator

The suite sets a suite-wide `builder: icarus` in `tests.yaml`, which resolves
the `icarus` entry in `root_config.yaml`'s `cfg-rtl-builder`. A `--builder`
CLI override still wins, so the same suite can be forced onto Verilator:

```bash
# Run on Icarus (the suite default) — requires iverilog + vvp on PATH:
#   brew install icarus-verilog   (macOS)
#   apt install iverilog          (Debian/Ubuntu)
cd verif/icarus_smoke
uv run rb test basic

# Force Verilator instead (CLI override beats the suite builder):
uv run rb -B verilator test basic
```

## Requirements / status

- **rtl_buddy** with per-suite/per-test `builder:` selection. Until that ships
  in the pinned release, validate against a local checkout via the
  `dev/local-rtl-buddy` override branch (see `AGENTS.md`).
- **Icarus Verilog** (`iverilog` + `vvp`) on `PATH` for the default builder.

This suite is intentionally **not** wired into `regression.yaml`: the per-push
and nightly CI run in a Verilator-only container without `iverilog`. Add it to
a dedicated Icarus CI job (or run it locally) rather than the default tiers.
