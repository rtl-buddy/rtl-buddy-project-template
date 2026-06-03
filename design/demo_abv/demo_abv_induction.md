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
`../../fpv/demo_abv/demo_abv_induction/demo_abv_induction_props.sv`, one per
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
cd fpv/demo_abv/demo_abv_induction

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

## A subtlety worth knowing: why raising `depth` makes `cnt != 26` pass

SymbiYosys `mode prove` does **temporal k-induction up to the BMC
depth** (`k = depth`), not 1-induction. Raising the depth can flip
`cnt != 26` from FAIL to PASS — and understanding *why* is the deepest
lesson in this demo.

### What induction is checking

At depth `k`, `prove` searches for a **counterexample-to-induction
(CTI)**: a legal sequence of `k+1` states

```
s0 → s1 → … → s(k-1) → sk
```

where the first `k` states satisfy `cnt != 26` and the last one
**violates** it (`cnt == 26`). Reachability is *not* required — these
states may be entirely unreachable. If such a CTI exists, induction
**fails** at that depth; if none exists, it **succeeds**. So the only
question is: *how long can a legal path ending in `cnt == 26` be?*

### The wrap-at-5 caps that path at 21 states

Walk backwards from `26`. The transition is
`next(x) = (x == 5) ? 0 : x + 1`, so the only predecessor of `26` is
`25`, of `25` is `24`, … giving the ramp

```
6 → 7 → 8 → … → 24 → 25 → 26      (21 states)
```

Now ask for the predecessor of `6`: it would have to be `5` (since
`5 + 1 = 6`) — **but `5` wraps to `0`, not `6`**, and no other value maps
to `6` either. So **`6` has no predecessor at all**; the wrap-at-5 makes
it a *source*. Every legal path ending at `26` therefore starts no
earlier than `6`, and its maximum length is fixed at **21 states**.

### So the depth decides the verdict

A CTI at depth `k` needs `k + 1` states ending at `26`:

| depth | states needed ending at 26 | exists? | result |
|---|---|---|---|
| **20** | 21 (`6..26`, exactly the ramp) | yes | **FAIL** |
| **21** | 22 (longer than the ramp) | no | PASS |
| **32** | 33 | no | PASS |

This demo pins **`depth: 20`** so `cnt != 26` lands on the *failing*
side — `26` against depth `20` is the exact boundary.

### Why this is a trap, not a fix

Bumping the depth to `32` and watching `cnt != 26` pass is **k-induction
getting lucky on the geometry**, not the property becoming inductive. It
still is not 1-inductive — the induction step can still sit on the
unreachable state `25` and step to `26`. The wider window only helps
because the wrap chops the unreachable ramp at a fixed length. It does
not generalise:

- a bigger gap (`cnt != 1000`) would need `depth >= ~996` before it
  passes;
- remove the wrap (a free-running counter) and the ramp into the bad
  value can be arbitrarily long, so **no finite depth** ever closes it.

The robust answer is the bottom-row rewrite, `cnt <= 5`. Its hypothesis
("`cnt <= 5` in the prior state") directly excludes `25` as a start
state, so it proves at **`k = 1`**, at any depth, regardless of
geometry. "Raise the depth until it goes green" is exactly the
anti-pattern this demo is teaching you to avoid.

## How this stays in `fpv_regression.yaml` despite an expected failure

`demo_abv_induction_noninductive_prove` is **expected to FAIL** — that
failure *is* the lesson. It is marked `xfail_strict: true` in `fpv.yaml`,
so `rb fpv` reports it as **XFAIL**, which counts as a pass. That lets
the suite live in `fpv_regression.yaml` (it is listed there) without
turning `rb fpv-regression` red. The *strict* variant also means that if
the property ever *starts* proving (e.g. someone raises the depth past
the induction boundary), it becomes an **XPASS** that counts as a
**failure** — a deliberate red flag that the demo no longer demonstrates
the lesson and the marker is now stale. (Plain `xfail: true` would
instead let such an XPASS pass silently; strict is the right choice for a
regression guard.)

**Version requirement:** FPV `xfail` support landed in `rtl_buddy`
v6.1.0 ([PR rtl-buddy/rtl_buddy#256](https://github.com/rtl-buddy/rtl_buddy/pull/256)),
and this project pins a compatible `rtl_buddy`, so `rb fpv-regression`
stays green here. On an older `rtl_buddy` the `xfail_strict:` key is
silently ignored and this verification reports a plain **FAIL**.
