# `verif/demo_tiny_alu/` — SV/LVM Suite (vector-driven from Python golden)

The SV-side demonstrator suite for the sandbox tiny ALU. Pairs with
[`verif/demo_tiny_alu_cocotb/`](../sandbox_cocotb/), which runs the **same
DUT** against the **same Python golden**
([`spec/demo_tiny_alu/tiny_alu_model.py`](../../spec/demo_tiny_alu/tiny_alu_model.py))
from cocotb.

## How it works

1. **Preproc** — [`preproc.py`](preproc.py) runs before compile/sim.
   It picks a stimulus sequence based on the test's `TEST` plusarg
   and runs each `(op, a, b)` through `AluModel.compute()` to get the
   expected `(y, zf, cf, nf, vf)`. Both are written into
   `<artefacts>/<test>/vectors.txt`. The absolute path is injected
   back into the test's plusargs as `VECTORS=...`.
2. **Sim** — [`tb_top.sv`](tb_top.sv) loads `vectors.txt`, drives one
   `(op, a, b)` per clock, then compares the registered DUT output
   against the expected for that vector. Any mismatch increments LVM
   `nerr` and the test fails. There is no inline SV reference any
   more — the Python golden is the single source of truth.
3. **Coverage** — [`cov_alu.sv`](cov_alu.sv) cover-property labels
   match the `SAND-FUNC-*` IDs in
   [`spec/demo_tiny_alu/specs.yaml`](../../spec/demo_tiny_alu/specs.yaml).
4. **Report** — [`build_report.py`](build_report.py) is a *visualization*
   step only. It does not re-check correctness (the simulator already
   did). It reads PASS/FAIL from `test.log`, captures a Surfer
   headless PNG using [`tb_top.surfer`](tb_top.surfer), and emits
   `report/<test>.md` showing objective + coverage IDs + waveform.

## What this suite shows

| `rtl_buddy` capability   | Where to look                                                       |
|--------------------------|---------------------------------------------------------------------|
| Spec authoring           | [`spec/demo_tiny_alu/README.md`](../../spec/demo_tiny_alu/README.md)            |
| Spec → functional cov    | `cov_alu.sv` — cover labels match `SAND-FUNC-*` IDs                  |
| Test planning            | [`testplan.md`](testplan.md) (`covers:` mirrored in `tests.yaml`)   |
| Coverage collection      | `rb -M cov regression --coverage-merge --coverage-html --coverage-coverview` |
| Coverview dashboard      | [`../../coverview.md`](../../coverview.md)                          |
| Preproc plugin           | `preproc.py` — generates stimulus + expected via Python golden       |
| Golden-model cosim (SV)  | tb_top reads `vectors.txt`, compares per-cycle                       |
| Surfer integration       | `tb_top.surfer` layout, autoloaded by `rb wave <test>`              |
| DV report w/ waveforms   | `build_report.py` — visualization only (PASS/FAIL from sim)         |

## Running

```bash
cd verif/demo_tiny_alu

# one test, debug mode (FST trace + vectors.txt produced)
uv run rb test basic

# whole project + cocotb peer with coverage
uv run rb -M cov regression \
  --coverage-merge --coverage-html --coverage-coverview \
  -c ../../regression.yaml

# spec → coverage closure check
uv run rb spec check-coverage

# open Surfer with the tb layout
uv run rb wave basic

# generate the DV report (markdown + waveform PNGs, no re-check)
uv run python build_report.py
open report/index.md
```

## Files

| File              | Purpose                                                                |
|-------------------|------------------------------------------------------------------------|
| `preproc.py`      | Generates `vectors.txt` from the Python golden, injects `VECTORS=` plusarg |
| `tb_top.sv`       | Vector-driven LVM testbench; per-cycle compare; txn log               |
| `cov_alu.sv`      | Covergroup / cover properties (SAND-FUNC-* IDs)                       |
| `tests.yaml`      | Per-test `covers:` linked to spec IDs; wires `preproc:`               |
| `testplan.md`     | Human plan + pass criteria                                             |
| `tb_top.surfer`   | Surfer signal layout (also used as headless capture base)              |
| `build_report.py` | Visualization: PASS/FAIL + waveform PNG + objective per test          |
