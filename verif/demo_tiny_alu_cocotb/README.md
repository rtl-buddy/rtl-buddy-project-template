# `verif/demo_tiny_alu_cocotb/` — cocotb Cosim Suite

The cocotb peer of [`verif/demo_tiny_alu/`](../sandbox/). Same DUT
([`design/demo_tiny_alu/demo_tiny_alu.sv`](../../design/demo_tiny_alu/demo_tiny_alu.sv)), same Python
golden ([`spec/demo_tiny_alu/tiny_alu_model.py`](../../spec/demo_tiny_alu/tiny_alu_model.py)),
different driver. Read both READMEs together to see the
"one DUT, one spec, two cosim flows" demonstration.

## Why a peer suite

The SV/LVM suite uses an **inline SV reference function** that mirrors
the spec; correctness of that reference is established by post-run replay
through `tiny_alu_model.py`. The cocotb suite uses `tiny_alu_model.py`
**live**, every cycle, with no SV reference at all. If the SV reference
silently drifts from the spec, the cocotb suite catches it. If the
cocotb test logic drifts, the SV scoreboard catches it. The spec is the
shared truth.

## What this suite shows

- `rtl_buddy` cocotb integration (`testbenches[].cocotb.module:` in
  `tests.yaml`, no SV testbench wrapper)
- Live golden-model cosimulation: every DUT output is compared to
  `AluModel.compute()` in the same Python process
- Re-use of the spec's executable form across SV and cocotb flows

## Running

```bash
cd verif/demo_tiny_alu_cocotb

uv run rb test cocotb_random        # one cocotb test
uv run rb test cocotb_flags

# whole project regression (this suite + leaf-IP suites + sandbox + demo_tiny_alu_subsys)
uv run rb regression -c ../../regression.yaml
```

The DUT is loaded as `toplevel: demo_tiny_alu`; cocotb drives `clk/rst/op/a/b`
directly. Imports of `tiny_alu_model` are resolved by inserting
`spec/demo_tiny_alu/` onto `sys.path` from the test module.

## Files

| File                   | Purpose                                                                |
|------------------------|------------------------------------------------------------------------|
| `tests.yaml`           | rtl_buddy test configs (one cocotb module per rtl_buddy test)          |
| `_alu_common.py`       | shared helpers: clock/reset, drive + per-cycle scoreboard vs golden    |
| `test_alu_random.py`   | `cocotb_random` — 256 random ops scoreboarded against `AluModel`       |
| `test_alu_flags.py`    | `cocotb_flags` — directed flag corners (C/V for ADD/SUB)               |
