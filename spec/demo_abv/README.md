# `demo_abv` — Formal → Spec Traceability

Spec blocks for the three `demo_abv` counters. They exist to demonstrate
the **formal** half of `rb spec`: coverage items closed by `rb fpv`
verifications rather than by simulation tests.

An `fpv.yaml` verification may declare `covers:` exactly as a test in
`tests.yaml` does (rtl-buddy/rtl_buddy#385). `rb spec check-coverage`
discovers the formal runs through the root-level `fpv_regression.yaml`
(the `verif/` walk never reaches `fpv/`), so a proof counts towards a
coverage item the same way a test does, and the design knowledge graph
gets the matching `fpv run → coverage_item → spec block` chain.

One block per sub-block, mirroring `design/demo_abv/models.yaml`:

| Spec block | Closed by | Property source |
|---|---|---|
| `demo_abv_basic` | [`fpv/demo_abv/demo_abv_basic/fpv.yaml`](../../fpv/demo_abv/demo_abv_basic/fpv.yaml) | bound checker `demo_abv_basic_props.sv` |
| `demo_abv_induction` | [`fpv/demo_abv/demo_abv_induction/fpv.yaml`](../../fpv/demo_abv/demo_abv_induction/fpv.yaml) | checker tops in `demo_abv_induction_props.sv` |
| `demo_abv_features` | [`fpv/demo_abv/demo_abv_features/fpv.yaml`](../../fpv/demo_abv/demo_abv_features/fpv.yaml) | inline `` `ifdef FORMAL `` assertions + `_props_slang.sv` |

Per-block design documentation lives with the RTL under
[`design/demo_abv/`](../../design/demo_abv/); each block's `docs:` list
points at it.

## What the items claim

Every item names a property a shipped proof actually establishes. Two
deliberate omissions are worth calling out, because they are the point
of the demos rather than gaps:

- **`demo_abv_induction_noninductive_prove` declares no `covers:`.** It
  is an expected failure (`xfail_strict: true`) — `cnt != 26` is true of
  the design but not inductive, so that run establishes nothing. The
  same claim (`ABV-IND-NO-26`) is closed by the runs that *do* establish
  it: the BMC run (bounded reachability) and the companion prove run
  (k-induction, once `cnt != 6` prunes the counterexample ramp).
- **`demo_abv_features`' vacuous property and dead assume close no
  item.** `1'b0 |-> …` proves nothing about the design and the
  tautological `assume (en || !en)` constrains nothing; both exist so
  `rb fpv` can *report* them (vacuity, dead-assume). Only the reset
  assertion and the non-vacuous `en |-> cnt <= MAX` earn spec items.

## Try it

```bash
# from the repo root
uv run rb spec list
uv run rb spec check-design   --block demo_abv_basic --block demo_abv_induction --block demo_abv_features
uv run rb spec check-coverage --block demo_abv_basic --block demo_abv_induction --block demo_abv_features

# the same chain on the design knowledge graph
uv run rb graph build --force
uv run rb graph path \
  test:fpv/demo_abv/demo_abv_induction#demo_abv_induction_inductive_prove \
  spec:demo_abv_induction
```
