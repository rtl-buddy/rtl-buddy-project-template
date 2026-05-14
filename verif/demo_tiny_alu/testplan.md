# Sandbox SV/LVM Testplan

Authoritative test plan for the SV/LVM flow. Each test maps to:
- a stimulus sequence built by [`preproc.py`](preproc.py) from the
  Python golden ([`spec/demo_tiny_alu/tiny_alu_model.py`](../../spec/demo_tiny_alu/tiny_alu_model.py))
- one or more `SAND-FUNC-*` IDs from
  [`spec/demo_tiny_alu/specs.yaml`](../../spec/demo_tiny_alu/specs.yaml)
- pass criteria proven by the SV scoreboard reading expected results
  from the preproc-generated `vectors.txt`

## Tests

| Test         | Stimulus                                | Coverage targets                                                              |
|--------------|-----------------------------------------|-------------------------------------------------------------------------------|
| `basic`      | each opcode once with non-zero operands | `SAND-FUNC-RESET`, `SAND-FUNC-OP-*`                                           |
| `ops_sweep`  | progressive operands per opcode         | `SAND-FUNC-OP-*`, `SAND-FUNC-OPERAND-RANGE`                                   |
| `flags`      | directed corners (Z, N, C-ADD, C-SUB, V-ADD, V-SUB) | `SAND-FUNC-FLAG-Z`, `-N`, `-C-ADD`, `-C-SUB`, `-V-ADD`, `-V-SUB`  |
| `random`     | 256-cycle constrained-random            | `SAND-FUNC-OPERAND-RANGE`, `SAND-FUNC-FLAG-Z`, `SAND-FUNC-FLAG-N`             |

## Pass criteria

A test PASSES when **all** of the following hold:

1. **Preproc** runs cleanly and writes `vectors.txt` containing one
   row per cycle: `op, a, b, y, zf, cf, nf, vf`. The expected fields
   come from `AluModel.compute()` (the Python golden).
2. **SV scoreboard**: per-cycle compare in `tb_top.sv` produces zero
   mismatches across all rows of `vectors.txt`.
3. **LVM**: `nerr == 0` at end-of-test (i.e. `PASS` in `test.log`).
4. **Coverage objectives** for the test's listed `covers:` IDs are
   hit at least once in the merged covergroup database.

## Reproducing locally

```bash
cd verif/demo_tiny_alu
uv run rb test basic                       # one test, debug mode
uv run rb -M cov regression \
   --coverage-merge --coverage-html --coverage-coverview \
   -c ../../regression.yaml                # full suite + coverage
uv run rb wave basic                       # open Surfer with tb_top.surfer layout
uv run python build_report.py              # visualize report/<test>.md (no re-check)
```

## Cross-suite reference

For the same DUT driven from cocotb against the same Python golden,
see [`verif/demo_tiny_alu_cocotb/`](../sandbox_cocotb/). Both suites consume
[`spec/demo_tiny_alu/tiny_alu_model.py`](../../spec/demo_tiny_alu/tiny_alu_model.py) —
the SV side via `preproc.py` (generates expected results offline), the
cocotb side live every cycle. Drift in either direction surfaces from
the corresponding flow.
