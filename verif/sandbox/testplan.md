# Sandbox SV/LVM Testplan

Authoritative test plan for the SV/LVM cosim flow. Each test maps to:
- a stimulus pattern in `tb_top.sv`
- one or more `SAND-FUNC-*` IDs from [`spec/sandbox/specs.yaml`](../../spec/sandbox/specs.yaml)
- pass criteria proven by the SV scoreboard *and* by post-run replay through
  the Python golden ([`spec/sandbox/sandbox_model.py`](../../spec/sandbox/sandbox_model.py))

## Tests

| Test         | Stimulus                                | Coverage targets                                                              |
|--------------|-----------------------------------------|-------------------------------------------------------------------------------|
| `basic`      | each opcode once with non-zero operands | `SAND-FUNC-RESET`, `SAND-FUNC-OP-*`                                           |
| `ops_sweep`  | progressive operands per opcode         | `SAND-FUNC-OP-*`, `SAND-FUNC-OPERAND-RANGE`                                   |
| `flags`      | directed corners                        | `SAND-FUNC-FLAG-Z`, `-N`, `-C-ADD`, `-C-SUB`, `-V-ADD`, `-V-SUB`              |
| `random`     | 256-cycle constrained-random            | `SAND-FUNC-OPERAND-RANGE`, `SAND-FUNC-FLAG-Z`, `SAND-FUNC-FLAG-N`             |

## Pass criteria

A test PASSES when **all** of the following hold:

1. **SV scoreboard**: 0 mismatches between the registered DUT outputs and
   the inline SV reference function `ref_compute()` in `tb_top.sv`.
2. **LVM**: `nerr == 0` at end-of-test.
3. **Python golden equivalence**: `build_report.py` replays `txn.log`
   through `sandbox_model.py` and reports 0 divergences. This catches
   any silent drift between the SV reference and the spec.
4. **Coverage objectives** for the test's listed `covers:` IDs are hit at
   least once in the merged covergroup database.

## Reproducing locally

```bash
cd verif/sandbox
uv run rb test basic                       # one test, debug mode
uv run rb -M cov regression \
   --coverage-merge --coverage-html --coverage-coverview \
   -c ../../regression.yaml                # full suite + coverage
uv run rb wave basic                       # open Surfer with tb_top.surfer layout
uv run python build_report.py              # generate report/<test>.md + waveform PNGs
```

## Cross-suite reference

For the same DUT driven from cocotb against the same Python golden, see
[`verif/sandbox_cocotb/`](../sandbox_cocotb/). The cocotb suite is a
peer demonstrator, not a reimplementation: both consume `sandbox_model.py`
to make any spec drift visible from either direction.
