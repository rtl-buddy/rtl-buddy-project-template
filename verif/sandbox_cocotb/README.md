# `verif/sandbox_cocotb/` - cocotb Cosim Suite

The cocotb peer of [`verif/sandbox/`](../sandbox/). Same DUT
([`design/sandbox/alu.sv`](../../design/sandbox/alu.sv)), same Python
golden ([`spec/sandbox/sandbox_model.py`](../../spec/sandbox/sandbox_model.py)),
different driver. Read both READMEs together to see the
"one DUT, one spec, two cosim flows" demonstration.

## Why a peer suite

The SV/LVM suite consumes `sandbox_model.py` offline in
[`verif/sandbox/preproc.py`](../sandbox/preproc.py): it expands each
stimulus sequence into vectors with expected `(y, zf, cf, nf, vf)`
results before simulation, and [`verif/sandbox/tb_top.sv`](../sandbox/tb_top.sv)
checks the DUT against those expected values cycle by cycle.

This cocotb suite consumes that same `sandbox_model.py` live in Python
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
cd verif/sandbox_cocotb

uv run rb test cocotb_random        # one cocotb test
uv run rb test cocotb_flags

# whole project regression (this suite + leaf-IP suites + sandbox + alu_accel)
uv run rb regression -c ../../regression.yaml
```

The DUT is loaded as `toplevel: alu`; cocotb drives `clk/rst/op/a/b`
directly. Imports of `sandbox_model` are resolved by inserting
`spec/sandbox/` onto `sys.path` from the test module.

## Files

| File                   | Purpose                                                                |
|------------------------|------------------------------------------------------------------------|
| `tests.yaml`           | rtl_buddy test configs (one cocotb module per rtl_buddy test)          |
| `_alu_common.py`       | shared helpers: clock/reset, drive + per-cycle scoreboard vs golden    |
| `test_alu_random.py`   | `cocotb_random` - 256 random ops scoreboarded against `AluModel`       |
| `test_alu_flags.py`    | `cocotb_flags` - directed flag corners (C/V for ADD/SUB)               |
