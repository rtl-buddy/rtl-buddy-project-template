# `verif/sandbox/` — SV/LVM Cosim Suite

The SV-side demonstrator suite for the sandbox tiny ALU. Pairs with
[`verif/sandbox_cocotb/`](../sandbox_cocotb/), which runs the **same DUT**
against the **same Python golden** ([`spec/sandbox/sandbox_model.py`](../../spec/sandbox/sandbox_model.py))
from cocotb. Read both READMEs together to see the full
"one DUT, one spec, two cosim flows" demonstration.

## What this suite shows

| `rtl_buddy` capability   | Where to look                                                       |
|--------------------------|---------------------------------------------------------------------|
| Spec authoring           | [`spec/sandbox/README.md`](../../spec/sandbox/README.md)            |
| Spec → functional cov    | `cov_alu.sv` — covergroup bins named after `SAND-FUNC-*` IDs        |
| Test planning            | [`testplan.md`](testplan.md) (`covers:` mirrored in `tests.yaml`)   |
| Coverage collection      | `rb -M cov regression --coverage-merge --coverage-html --coverage-coverview` |
| Coverview dashboard      | [`../../coverview.md`](../../coverview.md)                          |
| Golden-model cosim (SV)  | inline `ref_compute()` in `tb_top.sv` + post-run replay through `sandbox_model.py` |
| Surfer integration       | `tb_top.surfer` layout + `rb wave <test>` opens live viewer         |
| DV report w/ waveforms   | `build_report.py` — emits `report/<test>.md` with headless surfer captures |

## Running

```bash
cd verif/sandbox

# one test, debug mode (FST trace produced)
uv run rb test basic

# the whole suite + cocotb peer with coverage
uv run rb -M cov regression \
  --coverage-merge --coverage-html --coverage-coverview \
  -c ../../regression.yaml

# spec → coverage closure check
uv run rb spec check-coverage

# open Surfer with the tb layout, live signal annotation in your editor
uv run rb wave basic

# generate the DV report (markdown + waveform PNGs)
uv run python build_report.py
open report/index.md
```

## Files

| File              | Purpose                                                                |
|-------------------|------------------------------------------------------------------------|
| `tb_top.sv`       | LVM testbench: directed sequences (`+TEST=`), inline scoreboard, txn log |
| `cov_alu.sv`      | Covergroup `cg_alu` + `SAND_FUNC_RESET` cover property                 |
| `tests.yaml`      | Per-test `covers:` linked to spec IDs                                  |
| `testplan.md`     | Human plan + pass criteria                                             |
| `tb_top.surfer`   | Surfer signal layout (also used as headless capture base)              |
| `build_report.py` | Replay txn log through Python golden, capture waveforms, emit report  |
