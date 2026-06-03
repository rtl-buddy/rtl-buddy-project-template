# demo_abv — assertion-based & formal verification demos

A family of three small counters that together exercise rtl_buddy's
Assertion-Based Verification (ABV) and formal surface end to end. They
share this directory and a single `models.yaml`; each remains an
independent model (its name is unchanged), with its own property files,
testbench, and run configs under `fpv/<name>/` and `verif/<name>/`.

## The blocks

| Model | Teaches | Run from | Detail |
|---|---|---|---|
| `demo_fpv_counter` | The basics of `rb fpv` — safety (`bmc`), reset, and cover properties on a bound checker; also the `rb mut` reference block | `fpv/demo_fpv_counter/` | [demo_fpv_counter.md](demo_fpv_counter.md) |
| `demo_abv_features` | ABV end to end — testbench-side SVA via `rb test`, plus `rb fpv` reporting **COI**, **dead-assume**, and slang-fronted **vacuity** | `fpv/demo_abv_features/`, `verif/demo_abv_features/` | [demo_abv_features.md](demo_abv_features.md) |
| `demo_abv_induction` | BMC vs induction — a true-but-not-inductive property (`cnt != 26`) that passes `bmc` yet fails `prove`, and the inductive-invariant fix (`cnt <= 5`); rides in regression via `xfail_strict` | `fpv/demo_abv_induction/` | [demo_abv_induction.md](demo_abv_induction.md) |

`demo_abv_features` is the inline-assertion variant of `demo_fpv_counter`
(same counter, assertions in the DUT instead of a bound checker).
`demo_abv_induction` is a separate wrapping counter built purely to teach
the induction lesson.

## Quick start

```bash
# basics: safety + cover (slang frontend — see tools/yosys-slang/)
cd fpv/demo_fpv_counter && rb fpv demo_fpv_counter_safety

# ABV reporting: COI + dead-assume, then slang-fronted vacuity
cd fpv/demo_abv_features && rb fpv demo_abv_features_safety
                            rb fpv demo_abv_features_vacuity
# and the testbench-side SVA in simulation
cd verif/demo_abv_features && rb test smoke_with_sva

# BMC-vs-induction (the prove run is an expected XFAIL)
cd fpv/demo_abv_induction && rb fpv
```

## Layout

```text
design/demo_abv/
├── README.md                 # this overview
├── models.yaml               # shared config: the three models below
├── demo_fpv_counter.sv       # + demo_fpv_counter.md
├── demo_abv_features.sv      # + demo_abv_features.md
└── demo_abv_induction.sv     # + demo_abv_induction.md
```

The property files, testbenches, and `fpv.yaml` / `tests.yaml` /
`mut.yaml` run configs live under `fpv/<name>/` and `verif/<name>/`,
unchanged by this directory grouping.
