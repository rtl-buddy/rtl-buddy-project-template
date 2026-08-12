# demo_abv_features — Assertion-Based Verification end-to-end demo

A small saturating counter authored to exercise rtl_buddy's
Assertion-Based Verification (ABV) surface across both simulation and
formal flows. Use this demo to verify that the four ABV features land
correctly in your environment.

## What it demonstrates

| Feature | Where to look | What you should see |
|---|---|---|
| **#129 — SVA in `rb test`** | `verif/demo_abv/demo_abv_features/` | `assertions: true` in `tests.yaml` injects Verilator `--assert`; the results table grows an **Assertions** column |
| **#136 — COI coverage** | `fpv/demo_abv/demo_abv_features/` | `rb fpv` results table grows a **COI** column showing `89% (8/9)` — the fraction of design cells in the assertion's cone of influence |
| **#135 — Dead-assume detection** | `fpv/demo_abv/demo_abv_features/` | Results table grows an **Assumes** column showing `0 used, 1 dead` — the intentionally tautological `assume (en \|\| !en)` is flagged as structurally dead |
| **#134 — Vacuity covers** | `fpv/demo_abv/demo_abv_features/` (`demo_abv_features_vacuity` verification, slang-fronted) | Results table grows a **Vacuity** column showing `1/2 vacuous` — `p_safe_count` (antecedent `en`) reaches its cover, `p_vacuous` (antecedent `1'b0`) is flagged as unreachable. Reads `demo_abv_features_props_slang.sv` via `frontend: slang` since yosys's native verilog frontend does not parse `\|->` |
| **#367 — Per-cover-point results** | `verif/demo_abv/demo_abv_features/tb_top.sv` | Three labeled `cover property` statements, two reachable and one not, so the **Coverage** column shows `F:0.67`. Under `--machine`, `payload.coverage.covers` names each one with its hit count |

## Files

- `demo_abv_features.sv` — DUT with both the design logic and the
  formal-only `assert` / `assume` properties (wrapped in
  `` `ifdef FORMAL `` so only `rb fpv` sees them).
- `models.yaml` — shared `demo_abv` family model config; this block is
  the `demo_abv_features` entry.
- `../../fpv/demo_abv/demo_abv_features/fpv.yaml` — FPV configuration.
- `../../verif/demo_abv/demo_abv_features/` — Verilator test bench with a
  testbench-side SVA assertion for the `rb test` demo.

## Running

```bash
# From a project that has rtl_buddy installed:

# rb test demo — Verilator with SVA compiled in
cd verif/demo_abv/demo_abv_features
rb test smoke_with_sva

# rb fpv demo — sby + yosys COI walk + dead-assume
cd fpv/demo_abv/demo_abv_features
rb fpv demo_abv_features_safety

# rb fpv demo — slang-fronted vacuity covers
rb fpv demo_abv_features_vacuity
```

## Why the assertions live in different places

Inline `assume` statements break under Verilator's default x-state
simulation: at t=0 the input signals are x-valued (from
`--x-initial unique`) and the assume's expression evaluates to x,
which Verilator treats as a runtime failure. Guarding the assume with
`` `ifdef FORMAL `` keeps it visible to yosys's `read -formal` (which
defines the macro) and invisible to Verilator.

The testbench-side property (`CNT_MONOTONE` in
`verif/demo_abv/demo_abv_features/tb_top.sv`) uses SVA `disable iff (!rst_n)`
to skip evaluation during reset, which is the safer pattern for
Verilator-driven simulation.

## Cover properties

The same testbench carries three labeled `cover property` statements.
`assertions: true` already injects `--coverage-user`, so they are counted
on every run and roll up into the `F:` (functional) figure in the
**Coverage** column — `F:0.67`, two of three.

`CNT_STALLED_WHILE_DISABLED` is deliberately unreachable: `en` is never
deasserted after reset release. It is there to show that an uncovered
point is *reported* with `hits: 0` rather than dropped, which is what a
consumer grading verification-plan items needs — a silent absence and a
recorded zero mean very different things.

The labels are the point. Under `--machine`, each is reported
individually in `payload.coverage.covers` as
`{name, file, line, module, hits}`, on both the per-test rows and the
run-level rollup:

```json
{"name": "CNT_REACHED_MAX", "file": "../../tb_top.sv", "line": 49,
 "module": "tb_top", "hits": 2}
```

Naming them after intent rather than the expression is what makes them
mappable back to a plan item. Requires `rtl_buddy` with per-cover-point
reporting (#367); older versions still simulate the covers and report the
`F:` scalar, just without the per-point list.

Vacuity (#134) is exercised by the `demo_abv_features_vacuity`
verification, which reads `fpv/demo_abv/demo_abv_features/demo_abv_features_props_slang.sv`
through the slang-fronted FPV path (`frontend: slang` in `fpv.yaml`).
The native yosys verilog frontend does not parse `|->` / `|=>`, so the
slang plugin is required — `cfg-fpv-tools[].opts.plugin-path` in
`root_config.yaml` must point at your built `slang.so` (the template
ships with the sibling-checkout default `../yosys-slang/build/slang.so`,
matching the precedent in `synth/demo_slang_pkg/synth.yaml`).
