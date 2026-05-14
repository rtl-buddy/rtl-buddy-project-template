# `verif/demo_tiny_alu_cocotb/` — cocotb Cosim Suite

The cocotb peer of [`verif/demo_tiny_alu/`](../demo_tiny_alu/). Same DUT
([`design/demo_tiny_alu/demo_tiny_alu.sv`](../../design/demo_tiny_alu/demo_tiny_alu.sv)), same Python
golden ([`spec/demo_tiny_alu/tiny_alu_model.py`](../../spec/demo_tiny_alu/tiny_alu_model.py)),
different driver. Read both READMEs together to see the
"one DUT, one spec, two cosim flows" demonstration.

## Why a peer suite

The SV/LVM suite consumes `tiny_alu_model.py` offline in
[`verif/demo_tiny_alu/preproc.py`](../demo_tiny_alu/preproc.py): it expands each
stimulus sequence into vectors with expected `(y, zf, cf, nf, vf)`
results before simulation, and [`verif/demo_tiny_alu/tb_top.sv`](../demo_tiny_alu/tb_top.sv)
checks the DUT against those expected values cycle by cycle.

This cocotb suite consumes that same `tiny_alu_model.py` live in Python
while the DUT is running. The two suites exercise different harnesses,
but both point at the same executable spec. If either harness drifts,
one of the flows fails loudly.

## What this suite shows

- `rtl_buddy` cocotb integration (`testbenches[].cocotb.module:` in
  `tests.yaml`, no SV testbench wrapper)
- Live golden-model cosimulation: every DUT output is compared to
  `AluModel.compute()` in the same Python process
- Re-use of the spec's executable form across offline (SV preproc) and
  live (cocotb) verification flows

## Running

```bash
cd verif/demo_tiny_alu_cocotb

uv run rb test cocotb_random        # one cocotb test
uv run rb test cocotb_flags

# whole project regression (this suite + base-IP suites + demo_tiny_alu + demo_tiny_alu_subsys + demo_cdc_src_sync)
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
