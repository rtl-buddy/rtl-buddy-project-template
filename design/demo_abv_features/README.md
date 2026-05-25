# demo_abv_features — Assertion-Based Verification end-to-end demo

A small saturating counter authored to exercise rtl_buddy's
Assertion-Based Verification (ABV) surface across both simulation and
formal flows. Use this demo to verify that the four ABV features land
correctly in your environment.

## What it demonstrates

| Feature | Where to look | What you should see |
|---|---|---|
| **#129 — SVA in `rb test`** | `verif/demo_abv_features/` | `assertions: true` in `tests.yaml` injects Verilator `--assert`; the results table grows an **Assertions** column |
| **#136 — COI coverage** | `fpv/demo_abv_features/` | `rb fpv` results table grows a **COI** column showing `89% (8/9)` — the fraction of design cells in the assertion's cone of influence |
| **#135 — Dead-assume detection** | `fpv/demo_abv_features/` | Results table grows an **Assumes** column showing `0 used, 1 dead` — the intentionally tautological `assume (en \|\| !en)` is flagged as structurally dead |
| **#134 — Vacuity covers** | (not yet exercised here) | Requires `\|->` SVA properties; lights up automatically once a slang-fronted FPV path is wired in. The umbrella tracks this in [rtl_buddy#134](https://github.com/rtl-buddy/rtl_buddy/issues/134) |

## Files

- `demo_abv_features.sv` — DUT with both the design logic and the
  formal-only `assert` / `assume` properties (wrapped in
  `` `ifdef FORMAL `` so only `rb fpv` sees them).
- `models.yaml` — single-file leaf model.
- `../../fpv/demo_abv_features/fpv.yaml` — FPV configuration.
- `../../verif/demo_abv_features/` — Verilator test bench with a
  testbench-side SVA assertion for the `rb test` demo.

## Running

```bash
# From a project that has rtl_buddy installed:

# rb test demo — Verilator with SVA compiled in
cd verif/demo_abv_features
rb test smoke_with_sva

# rb fpv demo — sby + yosys COI walk
cd fpv/demo_abv_features
rb fpv demo_abv_features_safety
```

## Why the assertions live in different places

Inline `assume` statements break under Verilator's default x-state
simulation: at t=0 the input signals are x-valued (from
`--x-initial unique`) and the assume's expression evaluates to x,
which Verilator treats as a runtime failure. Guarding the assume with
`` `ifdef FORMAL `` keeps it visible to yosys's `read -formal` (which
defines the macro) and invisible to Verilator.

The testbench-side property (`CNT_MONOTONE` in
`verif/demo_abv_features/tb_top.sv`) uses SVA `disable iff (!rst_n)`
to skip evaluation during reset, which is the safer pattern for
Verilator-driven simulation.

A future demo can exercise vacuity (#134) by adding `|->` properties
through a slang-fronted FPV path once that lands in rtl_buddy.
