# demo_abv — assertion-based & formal verification demos

A family of three small counters that together exercise rtl_buddy's
Assertion-Based Verification (ABV) and formal surface end to end. They
share this directory and a single `models.yaml`; each remains an
independent model (its name is unchanged), with its own property files,
testbench, and run configs under `fpv/<name>/` and `verif/<name>/`.

## The blocks

| Model | Teaches | Run from | Detail |
|---|---|---|---|
| `demo_abv_basic` | The basics of `rb fpv` — safety (`bmc`), reset, and cover properties on a bound checker; also the `rb mut` reference block | `fpv/demo_abv/demo_abv_basic/` | [demo_abv_basic.md](demo_abv_basic.md) |
| `demo_abv_features` | ABV end to end — testbench-side SVA and labeled **cover properties** via `rb test`, plus `rb fpv` reporting **COI**, **dead-assume**, and slang-fronted **vacuity** | `fpv/demo_abv/demo_abv_features/`, `verif/demo_abv/demo_abv_features/` | [demo_abv_features.md](demo_abv_features.md) |
| `demo_abv_induction` | BMC vs induction — a true-but-not-inductive property (`cnt != 26`) that passes `bmc` yet fails `prove`, plus both fixes (the inductive invariant `cnt <= 5`, and a companion assertion `cnt != 6` that makes the pair prove together); rides in regression via `xfail_strict` | `fpv/demo_abv/demo_abv_induction/` | [demo_abv_induction.md](demo_abv_induction.md) |

`demo_abv_features` is the inline-assertion variant of `demo_abv_basic`
(same counter, assertions in the DUT instead of a bound checker).
`demo_abv_induction` is a separate wrapping counter built purely to teach
the induction lesson.

## Spec traceability

Each of the three models links to its own block in
[`spec/demo_abv/specs.yaml`](../../spec/demo_abv/specs.yaml), and every
verification in `fpv/demo_abv/<block>/fpv.yaml` declares a `covers:`
list naming the coverage items its proof establishes — the formal
counterpart of a test's `covers:` in `tests.yaml`. So these blocks close
their spec items with proofs rather than simulation:

```bash
uv run rb spec check-coverage --block demo_abv_basic
uv run rb graph path \
    test:fpv/demo_abv/demo_abv_basic#demo_abv_basic_safety spec:demo_abv_basic
```

`demo_abv_induction_noninductive_prove` deliberately declares no
`covers:` — it is an expected failure, so it establishes nothing. See
[`spec/demo_abv/README.md`](../../spec/demo_abv/README.md).

`demo_abv_basic` additionally ships the `rb mut` mutation-testing
reference: two campaigns (`mut.yaml` and `mut_cover.yaml`) mutate the same
design but score against **different kill oracles** — the safety proof vs
the cover proof — to show that one property alone is not a sufficient
oracle (each is the other's blind spot). The engine (`rtl-buddy-xeno`) is
pinned as a git source in `pyproject.toml`, so `rb mut` runs from a clean
`uv sync`. Full detail in [demo_abv_basic.md](demo_abv_basic.md#mutation-testing).

## Quick start

```bash
# basics: safety + cover (slang frontend — see tools/yosys-slang/)
cd fpv/demo_abv/demo_abv_basic && rb fpv demo_abv_basic_safety

# mutation testing: the same mutants scored against two different oracles
cd fpv/demo_abv/demo_abv_basic && rb mut run -c mut.yaml
                                  rb mut run -c mut_cover.yaml

# ABV reporting: COI + dead-assume, then slang-fronted vacuity
cd fpv/demo_abv/demo_abv_features && rb fpv demo_abv_features_safety
                            rb fpv demo_abv_features_vacuity
# and the testbench-side SVA in simulation
cd verif/demo_abv/demo_abv_features && rb test smoke_with_sva

# BMC-vs-induction (the prove run is an expected XFAIL)
cd fpv/demo_abv/demo_abv_induction && rb fpv
```

## Layout

```text
design/demo_abv/
├── README.md                 # this overview
├── models.yaml               # shared config: the three models below
├── demo_abv_basic.sv       # + demo_abv_basic.md
├── demo_abv_features.sv      # + demo_abv_features.md
└── demo_abv_induction.sv     # + demo_abv_induction.md
```

The property files, testbenches, and `fpv.yaml` / `tests.yaml` /
`mut.yaml` run configs live under `fpv/<name>/` and `verif/<name>/`,
unchanged by this directory grouping.
