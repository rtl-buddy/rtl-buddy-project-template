# demo_fpv_counter — the basic `rb fpv` (and `rb mut`) reference block

A small saturating up-counter. It's the entry-point formal demo: a clean
DUT with a bound SVA checker that exercises the three core property
kinds, and it doubles as the `rb mut` (mutation-testing) reference.

## The design

`demo_fpv_counter.sv` increments `cnt` when `en` is high, saturating at
`MAX` (default 5), with an async `rst_n` to 0 and a power-on value of 0.

One subtlety worth knowing (called out in the source): **`MAX` is
deliberately *not* `2**WIDTH - 1`.** With `MAX=5` and `WIDTH=3`, `cnt`
spans `0..7`, so `6` and `7` are representable overflow states the safety
proof can actually catch. If `MAX` filled the width exactly, `cnt <= MAX`
would be vacuously true (the counter physically can't exceed it) and
nothing — not a bug, not a mutation — could falsify it.

## The properties

The checker `fpv/demo_fpv_counter/demo_fpv_counter_props.sv` is bound
into the DUT (so the design RTL stays free of formal-only constructs) and
proves three things:

| Kind | Property | sby mode |
|---|---|---|
| **Safety** | the counter never exceeds `MAX` | `bmc` |
| **Reset** | after reset the counter is exactly 0 | `bmc` |
| **Cover** | a trace exists where the counter reaches `MAX` | `cover` |

Because the checker reaches the DUT via a SystemVerilog `bind`, the suite
sets `frontend: slang` — the native yosys verilog frontend silently drops
`bind` directives. See `../../tools/yosys-slang/SETUP_OSX.md` for building
the plugin that `cfg-fpv-tools[].opts.plugin-path` points at.

## Running it

```bash
cd fpv/demo_fpv_counter

# Safety proof (bounded): counter never overflows past MAX
rb fpv demo_fpv_counter_safety

# Cover: a trace exists where counter == MAX
rb fpv demo_fpv_counter_reaches_max
```

## Mutation testing

This block is also the `rb mut` reference. `fpv/demo_fpv_counter/mut.yaml`
(and `mut_cover.yaml`) mutate `demo_fpv_counter.sv` and check that the
property set *kills* the mutants — i.e. that the proofs are actually
sensitive to the logic, not vacuously passing. The reset property is the
one that makes dropping the design's reset assignment observable.

## Relationship to the other `demo_abv` blocks

`demo_abv_features` is the **inline-assertion variant** of this counter —
same shape, but it carries its `assert`/`assume` statements *in the DUT*
(under `` `ifdef FORMAL ``) so both `rb test` and `rb fpv` see one
property set. `demo_abv_induction` is a different (wrapping) counter used
purely to teach BMC-vs-induction. See the [family README](README.md).
