# `verif/sandbox_cocotb/` — cocotb Cosim Suite

The cocotb peer of [`verif/sandbox/`](../sandbox/). Same DUT
([`design/sandbox/alu.sv`](../../design/sandbox/alu.sv)), same Python
golden ([`spec/sandbox/sandbox_model.py`](../../spec/sandbox/sandbox_model.py)),
different driver. Read both READMEs together to see the
"one DUT, one spec, two cosim flows" demonstration.

## Why a peer suite

The SV/LVM suite uses an **inline SV reference function** that mirrors
the spec; correctness of that reference is established by post-run replay
through `sandbox_model.py`. The cocotb suite uses `sandbox_model.py`
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
cd verif/sandbox_cocotb

uv run rb test cocotb_random        # one cocotb test
uv run rb test cocotb_flags

# whole project regression (this suite + verif/sandbox + verif/cocotb_ex)
uv run rb regression -c ../../regression.yaml
```

The DUT is loaded as `toplevel: alu`; cocotb drives `clk/rst/op/a/b`
directly. Imports of `sandbox_model` are resolved by inserting
`spec/sandbox/` onto `sys.path` from the test module.

## Files

| File           | Purpose                                                |
|----------------|--------------------------------------------------------|
| `tests.yaml`   | rtl_buddy test configs, declares cocotb module         |
| `test_alu.py`  | `@cocotb.test()` coroutines: `cocotb_random`, `cocotb_flags` |
