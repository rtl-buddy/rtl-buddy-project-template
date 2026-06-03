# demo_abv_induction — BMC vs induction, made observable

A deliberately tiny teaching block: a wrapping counter plus three
property checkers that show how a property can be **true** of a design
yet still **fail an inductive proof**. The point is to build the
instinct to write *inductive invariants* rather than properties that
only happen to be true.

This block is **formal-only** — it is never simulated, carries no reset
port, and relies on a power-on `initial` value to pin the formal base
case.

## The design

`demo_abv_induction.sv` is a 10-bit counter that walks
`0,1,2,3,4,5,0,1,...` — it wraps at 5. Its **reachable** state set is
exactly `{0..5}`; every value `> 5` is unreachable.

## The three properties

All three are *true* of the counter. They live in
`../../fpv/demo_abv_induction/demo_abv_induction_props.sv`, one per
checker module so each `rb fpv` verification can target exactly one via
`top:`.

| Property | True? | Inductive? | Why |
|---|---|---|---|
| `cnt != 6`  | yes | **yes** | nothing transitions *to* 6 — `5` wraps to `0`, so there is no predecessor of `6` at all |
| `cnt != 26` | yes | **no**  | the unreachable state `cnt == 25` steps to `26`; an induction engine starting from an arbitrary state can sit on `25` and walk into the violation |
| `cnt <= 5`  | yes | **yes** | the reachable set `{0..5}` is *closed* under the transition relation — the recommended way to write the intent |

The lesson is the middle row vs the bottom row: `cnt != 26` and
`cnt <= 5` express almost the same intent ("the counter stays small"),
but only `cnt <= 5` is an inductive invariant. Poking at a single
unreachable value (`!= 26`) leaves the induction step free to start on a
neighbouring unreachable state and break.

## Running it

```bash
cd fpv/demo_abv_induction

# 1) cnt != 26 under BMC — bounded search never reaches 26:      PASS
rb fpv demo_abv_induction_noninductive_bmc

# 2) cnt != 26 under prove — induction can't close it:           FAIL (expected)
rb fpv demo_abv_induction_noninductive_prove

# 3) cnt <= 5 under prove — inductive invariant:                 PASS
rb fpv demo_abv_induction_inductive_prove
```

Verifications 1 and 2 run the **same property** (`cnt != 26`) under
different modes — that side-by-side is the whole demo:

- **BMC** explores only the bounded reachable space starting from
  `cnt == 0`, never climbs past `5`, so it never witnesses `26`: **PASS**.
- **prove** adds the induction step, which starts from an *arbitrary*
  state. `cnt == 25 → 26` is a valid one-step counterexample-to-
  induction, so the property is not provable by induction: **FAIL**
  (sby reports `UNKNOWN` — the property is neither proved nor disproved;
  there is no *reachable* counterexample, it simply is not inductive).

Verification 3 shows the fix: rewrite the intent as the inductive
invariant `cnt <= 5`, which proves cleanly at any depth.

## A subtlety worth knowing: `prove` depth is `k` in k-induction

SymbiYosys `mode prove` does **temporal k-induction up to the BMC
depth**, not 1-induction. The induction window length is `depth`, and a
wider window is a *stronger* hypothesis. That interacts with this demo:

- The longest counterexample-to-induction ramp into `26` is
  `6 → 7 → … → 26` (21 states — it cannot start below `6`, because `5`
  wraps to `0` instead of advancing to `6`).
- So with `depth ≥ 21`, the `k`-induction window is wider than any
  such ramp and the wrap-at-5 discontinuity lets induction **succeed** —
  `cnt != 26` proves!
- With `depth < 21` the window is too short to span the ramp, a
  counterexample-to-induction fits inside it, and induction **fails**.

This demo pins `depth: 20` precisely so `cnt != 26` lands on the
*failing* side — the value `26` against depth `20` is the exact boundary.
Bump the depth to `32` and watch the same property start passing; that
is not a fix, it is k-induction getting lucky on a property that still
isn't inductive. The robust answer is the bottom-row rewrite (`cnt <= 5`),
which is 1-inductive and proves regardless of depth.

## Why this suite is not in `fpv_regression.yaml`

`demo_abv_induction_noninductive_prove` is **expected to FAIL** — that
failure *is* the lesson. `rb fpv-regression` treats any non-PASS as a
regression failure (there is no expected-fail / xfail marker in the FPV
schema today), so wiring this suite into `fpv_regression.yaml` would
turn the regression red. It is therefore kept as a standalone,
run-it-yourself teaching exhibit. If an `xfail:` marker is added to the
FPV config in a future `rtl_buddy`, the non-inductive verification can
be marked expected-fail and folded back into regression.
