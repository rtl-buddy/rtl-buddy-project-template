# demo_abv_basic — the basic `rb fpv` (and `rb mut`) reference block

A small saturating up-counter. It's the entry-point formal demo: a clean
DUT with a bound SVA checker that exercises the three core property
kinds, and it doubles as the `rb mut` (mutation-testing) reference.

## The design

`demo_abv_basic.sv` increments `cnt` when `en` is high, saturating at
`MAX` (default 5), with an async `rst_n` to 0 and a power-on value of 0.

One subtlety worth knowing (called out in the source): **`MAX` is
deliberately *not* `2**WIDTH - 1`.** With `MAX=5` and `WIDTH=3`, `cnt`
spans `0..7`, so `6` and `7` are representable overflow states the safety
proof can actually catch. If `MAX` filled the width exactly, `cnt <= MAX`
would be vacuously true (the counter physically can't exceed it) and
nothing — not a bug, not a mutation — could falsify it.

## The properties

The checker `fpv/demo_abv/demo_abv_basic/demo_abv_basic_props.sv` is bound
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
cd fpv/demo_abv/demo_abv_basic

# Safety proof (bounded): counter never overflows past MAX
rb fpv demo_abv_basic_safety

# Cover: a trace exists where counter == MAX
rb fpv demo_abv_basic_reaches_max
```

## Mutation testing

This block is also the `rb mut` reference. Mutation testing perturbs the
design — flip a `+` to `-`, negate a condition, drop an assignment — and
re-runs a proof as the **kill oracle**. A mutant is **killed** when the
proof flips PASS → FAIL (the property noticed the change) and **survives**
when the proof still passes (a hole: the property set is too weak to see
that mutation). The score is `killed / (killed + survived)`.

### Two oracles, two failure modes

The point of this demo is that **one property is not a sufficient oracle.**
It ships two campaigns over the same mutants, each using a different
verification as the kill oracle:

| Campaign | Kill oracle | Catches | Blind to |
|---|---|---|---|
| `mut.yaml` | `demo_abv_basic_safety` (bmc: `cnt <= MAX`) | mutants that push `cnt` **above** `MAX` | mutants that leave `cnt` stuck low |
| `mut_cover.yaml` | `demo_abv_basic_reaches_max` (cover: `cnt == MAX` reachable) | mutants that leave the counter **stuck low** so it never reaches `MAX` | mutants that overflow |

For example, an `assign_drop` mutant that removes the increment leaves
`cnt` stuck at 0 — the **safety** proof still passes (0 never exceeds
`MAX`, so it *survives*), but the **cover** proof fails (`MAX` is no longer
reachable, so it's *killed*). Each property is the other's blind spot;
running both is what shows the property set actually constrains the design.

### Running it

```bash
cd fpv/demo_abv/demo_abv_basic

rb mut list                    # enumerate mutation sites (no proof run)
rb mut run  -c mut.yaml        # safety-oracle campaign
rb mut run  -c mut_cover.yaml  # cover-oracle campaign
rb mut score -c mut.yaml       # kill/survive report
```

`rb mut list` works straight from a clean `uv sync` — this template pins
the `rtl-buddy-xeno` engine as a git source (it isn't on PyPI yet). A full
`rb mut run` additionally needs the built `yosys-slang` plugin, since the
oracle verifications are slang-fronted — the same plugin the rest of this
FPV demo already requires.

## Relationship to the other `demo_abv` blocks

`demo_abv_features` is the **inline-assertion variant** of this counter —
same shape, but it carries its `assert`/`assume` statements *in the DUT*
(under `` `ifdef FORMAL ``) so both `rb test` and `rb fpv` see one
property set. `demo_abv_induction` is a different (wrapping) counter used
purely to teach BMC-vs-induction. See the [family README](README.md).
