# RTL-Buddy Project Template

Starter RTL project to use [`rtl_buddy`](https://github.com/rtl-buddy/rtl_buddy).

A clean starting point that ships a runnable, end-to-end demonstrator
**built up from small components**. Each leaf IP (APB interface, two
CDC primitives, an async FIFO, a tiny ALU) has its own spec, testplan,
and runnable test. They compose into a multi-clock APB-mapped ALU
accelerator with PeakRDL-generated CSRs (`demo_tiny_alu_subsys`).

Together they exercise the main day-to-day `rtl_buddy` workflows — spec
traceability, test, regression, coverage, golden-model cosim (SV +
cocotb + SystemC), `rb wave` + headless Surfer captures, DV reports,
PeakRDL register generation, Yosys synthesis, OpenROAD P&R, CDC lint,
formal property verification, and AXI traffic profiling — so the
mechanics stay in focus instead of the DUT.

## Demonstrator at a Glance

The blocks shipped with this template fall into three categories. The
naming convention surfaces the category in the directory name:

- **Base IP** — leaf, reusable components with their own spec/verif
  (no prefix; named after the IP).
- **Workflow templates** — `template/` skeletons that show the
  expected spec/design/verif/test shape for a new block. Copy these
  when starting fresh.
- **Demo blocks** — `demo_*` end-to-end examples showing how the
  base IPs compose and how to exercise specific rtl_buddy capabilities.
  Safe to delete when starting a new project.

### Base IP

| IP                 | Role                                                         | Design                                                                | Spec                                              | Verif                                              |
|--------------------|--------------------------------------------------------------|-----------------------------------------------------------------------|---------------------------------------------------|----------------------------------------------------|
| `apb`              | AMBA APB4 SystemVerilog interface (modports)                 | [`design/apb/`](design/apb/)                                          | [`spec/apb/`](spec/apb/)                          | [`verif/apb/`](verif/apb/)                         |
| `ip_cdc_sync`      | Multi-flop level synchronizer                                | [`design/common/ip_cdc_sync.sv`](design/common/ip_cdc_sync.sv)        | [`spec/ip_cdc_sync/`](spec/ip_cdc_sync/)          | [`verif/ip_cdc_sync/`](verif/ip_cdc_sync/)         |
| `ip_cdc_handshake` | 4-phase req/ack vector CDC                                   | [`design/common/ip_cdc_handshake.sv`](design/common/ip_cdc_handshake.sv) | [`spec/ip_cdc_handshake/`](spec/ip_cdc_handshake/) | [`verif/ip_cdc_handshake/`](verif/ip_cdc_handshake/) |
| `ip_async_fifo`    | Gray-code dual-clock async FIFO                              | [`design/common/ip_async_fifo.sv`](design/common/ip_async_fifo.sv)    | [`spec/ip_async_fifo/`](spec/ip_async_fifo/)      | [`verif/ip_async_fifo/`](verif/ip_async_fifo/)     |

### Workflow templates

| Template       | What it shows                                                       | Path                                              |
|----------------|---------------------------------------------------------------------|---------------------------------------------------|
| `template`     | Spec → design → verif → coverage traceability for a fresh block     | [`design/template/`](design/template/), [`spec/template/`](spec/template/), [`verif/template/`](verif/template/) |

### Demo blocks

| Demo                  | What it exercises                                                            | Paths                                                                                                                            |
|-----------------------|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| `demo_tiny_alu`        | Tiny 8-bit ALU leaf compute with Python golden model + SV/LVM cosim          | [`design/demo_tiny_alu/`](design/demo_tiny_alu/), [`spec/demo_tiny_alu/`](spec/demo_tiny_alu/), [`verif/demo_tiny_alu/`](verif/demo_tiny_alu/) |
| `demo_tiny_alu_cocotb` | cocotb peer of `demo_tiny_alu` driving the same DUT against the same golden  | [`verif/demo_tiny_alu_cocotb/`](verif/demo_tiny_alu_cocotb/)                                                                       |
| `demo_tiny_alu_sc`     | SystemC + Verilator cosim peer of `demo_tiny_alu`, showing the same DUT driven from `sc_main()` | [`verif/demo_tiny_alu_sc/`](verif/demo_tiny_alu_sc/) |
| `demo_tiny_alu_subsys`      | Multi-clock APB-mapped ALU accelerator that composes apb + ip_cdc_* + ALU; also drives the `rb pnr` Nangate45 flow | [`design/demo_tiny_alu_subsys/`](design/demo_tiny_alu_subsys/), [`spec/demo_tiny_alu_subsys/`](spec/demo_tiny_alu_subsys/), [`verif/demo_tiny_alu_subsys/`](verif/demo_tiny_alu_subsys/), [`pnr/demo_tiny_alu_subsys/`](pnr/demo_tiny_alu_subsys/) |
| `demo_cdc_src_sync`   | Source-synchronous chain (A→B0/B1→C0/C1) exercising internal-pin `create_generated_clock` for SoC-scope CDC | [`design/demo_cdc_src_sync/`](design/demo_cdc_src_sync/), [`spec/demo_cdc_src_sync/`](spec/demo_cdc_src_sync/), [`verif/demo_cdc_src_sync/`](verif/demo_cdc_src_sync/) |
| `demo_abv_basic`    | Saturating up-counter with a bound SVA checker for `rb fpv` (bmc-proves no-overflow, cover-reaches saturation); also the `rb mut` reference block | [`design/demo_abv/`](design/demo_abv/) ([detail](design/demo_abv/demo_abv_basic.md)), [`fpv/demo_abv/demo_abv_basic/`](fpv/demo_abv/demo_abv_basic/) |
| `demo_abv_features`   | Assertion-Based Verification end-to-end — testbench-side SVA via `rb test` + `rb fpv` reporting **COI**, **dead-assume**, and slang-fronted **vacuity** (`1/2 vacuous`) on a tiny saturating counter | [`design/demo_abv/`](design/demo_abv/) ([detail](design/demo_abv/demo_abv_features.md)), [`verif/demo_abv/demo_abv_features/`](verif/demo_abv/demo_abv_features/), [`fpv/demo_abv/demo_abv_features/`](fpv/demo_abv/demo_abv_features/) |
| `demo_abv_induction`  | BMC-vs-induction teaching block — a wrapping counter whose `cnt != 26` is true but not inductive (passes BMC, fails `prove`), with the inductive-invariant fix `cnt <= 5`; rides in regression via `xfail_strict` | [`design/demo_abv/`](design/demo_abv/) ([detail](design/demo_abv/demo_abv_induction.md)), [`fpv/demo_abv/demo_abv_induction/`](fpv/demo_abv/demo_abv_induction/) |
| `demo_axi_2x2`        | Minimal 2×2 AXI4 crossbar demo with directed traffic, waveform-friendly back-pressure, and profiler-ready AXI bundle metadata | [`design/demo_axi_2x2/`](design/demo_axi_2x2/), [`verif/demo_axi_2x2/`](verif/demo_axi_2x2/) |

### Third-party IP

| IP                  | What it shows                                                                                       | Paths                                                                                                                            |
|---------------------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| `demo_pulp_platform_axi` | Vendoring third-party SV IP — pulp-platform AXI interconnect via git submodules, with a curated filelist, scoped Verilator lint waivers, a directed FIFO testbench, and an elaboration sweep across all adapter variants | [`design/demo_pulp_platform_axi/`](design/demo_pulp_platform_axi/), [`verif/demo_pulp_platform_axi/`](verif/demo_pulp_platform_axi/), [`vendor/pulp-platform/`](vendor/pulp-platform/) |

Out of the box, `rb regression -c regression.yaml -l 1000` exercises the
base IP suites plus the SV, cocotb, SystemC, subsystem, CDC, third-party
AXI, and 2×2 AXI demos from one top-level list — the bare `rb regression
-c regression.yaml` runs just the must-run **sanity tier** (`reglvl 0`,
what per-push CI uses; the heavier suites and the VCS source-sync demo
are reglvl-gated). `rb synth-regression -c synth_regression.yaml` covers
the alu leaf, the full subsystem, and the source-sync chain, while `rb
fpv-regression` proves the counter demo's never-overflow invariant and
reaches the saturated state via SymbiYosys + yices.

## Tooling Scope

`rtl_buddy` adapts to the toolchain your project already uses. In this
template the supported flows are:

- **Verilator** for the open-source compile/sim/regression/coverage path
- **VCS** for teams using Synopsys flows
- **SystemC + Verilator cosim** for C++-driven harnesses through `rb test`
- **Yosys** (rtl-buddy fork) for synthesis (generic + tech-mapped)
- **rtl-buddy-cdc** for `rb cdc` clock-domain-crossing lint
- **OpenROAD** for `rb pnr` (floorplan → P&R → optional GDSII streamout); KLayout for GDS rendering
- **cocotb** for Python-driven testbenches
- **Surfer** + WCP for live waveform viewing and headless capture
- **Coverview** for browser-based coverage dashboards
- **PeakRDL** for SystemRDL → SystemVerilog register block generation
- **SymbiYosys (`sby`)** for `rb fpv` formal property verification — `demo_abv_basic` and `demo_abv_features` + `fpv_regression.yaml` exercise the flow end-to-end (vacuity / COI / dead-assume reporting via the slang-fronted variant)
- **AXI profiler wiring** via the `demo_axi_2x2` manifest, attaching the `axi-perf` overlay to the real `tb_axi_2x2 → dut` hierarchy, ready for `rb axi-profile` once `rtl-buddy-axi-profiler` is installed

## Setup

External prerequisites:

- `uv`, Python 3.11
- A simulator on `PATH` — Verilator (open-source) and/or VCS
- `lcov` for LCOV/HTML coverage export — `brew install lcov` on macOS; `apt-get install lcov` on Debian/Ubuntu (needed for the `--coverage-html` step of `rb -M cov regression`)
- `coverview` (Antmicro) for the Coverview package path — see [`coverview.md`](coverview.md)
- Verible — `brew tap chipsalliance/verible && brew install verible` on macOS (optional, for `rb verible …`)
- Yosys — build the [rtl-buddy fork](https://github.com/rtl-buddy/yosys) onto `PATH` (optional, for `rb synth …`); macOS notes in [`tools/yosys/SETUP_OSX.md`](tools/yosys/SETUP_OSX.md)
- yosys-slang — build the yosys-slang plugin (optional; required for any synth or FPV analysis that sets `frontend: "slang"`). Use povik's [yosys-slang](https://github.com/povik/yosys-slang) for synth-only; use the [rtl-buddy fork's `rtl-buddy` branch](https://github.com/rtl-buddy/yosys-slang/tree/rtl-buddy) for `rb fpv` with concurrent SVA (`|->`, `|=>`) until [povik/yosys-slang#317](https://github.com/povik/yosys-slang/pull/317) merges upstream. macOS notes in [`tools/yosys-slang/SETUP_OSX.md`](tools/yosys-slang/SETUP_OSX.md).
- OpenROAD — build from source onto `PATH` (optional, for downstream P&R; macOS notes in [`tools/openroad/SETUP_OSX.md`](tools/openroad/SETUP_OSX.md))
- Surfer — build from the [rtl-buddy fork](https://github.com/rtl-buddy/surfer) onto `PATH` (optional, for `rb wave` and headless waveform capture)
- SymbiYosys (`sby`) plus a solver such as `yices`, `z3`, or `boolector` — required to run `demo_abv_basic`, `demo_abv_features`, and any `rb fpv …` suites; macOS: `brew install yices2` covers the solver, see [the FPV concept doc](https://rtl-buddy.github.io/rtl_buddy/latest/concepts/fpv/) for sby install. The `demo_abv_features` slang-fronted vacuity variant additionally needs the rtl-buddy/yosys-slang fork built per [`tools/yosys-slang/SETUP_OSX.md`](tools/yosys-slang/SETUP_OSX.md)

Sync the project environment after cloning:

```bash
uv sync --locked --python 3.11
```

`cocotb`, `pytest`, `info-process` (for the Coverview zip), `peakrdl` +
`peakrdl-regblock` (for CSR generation) and the pinned `rtl_buddy` are
all installed automatically.

If you plan to use the `demo_pulp_platform_axi` example, also initialise the
vendor submodules:

```bash
git submodule update --init --recursive
```

Install the `rtl_buddy` agent skill once per machine so Claude Code /
Codex workflows can use it:

```bash
uv run rb skill install
# or, project-scoped (writes .claude/skills/, .agents/skills/, both gitignored):
uv run rb skill install --project
```

## Repository Layout

```text
.
├── root_config.yaml        # builder, platform, Verible, synth, surfer, coverage, regression config
├── regression.yaml         # top-level sim regression list
├── synth_regression.yaml   # top-level synth regression list
├── fpv_regression.yaml     # top-level FPV regression list
├── design/
│   ├── apb/                # base IP — APB4 SV interface
│   ├── common/             # base IP — CDC primitives + ip_async_fifo
│   ├── template/           # workflow template — starter design files for a new block
│   ├── demo_tiny_alu/       # demo — tiny ALU leaf DUT
│   ├── demo_axi_2x2/       # demo — 2x2 AXI4 wrapper + profiler manifest
│   ├── demo_tiny_alu_subsys/     # demo — PeakRDL CSR + multi-clock top + compute wrapper
│   ├── demo_cdc_src_sync/  # demo — source-synchronous CDC reference (internal-pin clock forwarding)
│   ├── demo_abv_basic/   # demo — saturating counter exercised by `rb fpv`
│   ├── demo_abv_features/  # demo — ABV end-to-end (SVA in `rb test` + slang-fronted `rb fpv` vacuity)
│   └── demo_pulp_platform_axi/  # third-party — filelists + Verilator waivers for the vendored AXI IP
├── spec/
│   ├── apb/  ip_cdc_sync/  ip_cdc_handshake/  ip_async_fifo/   # base IP specs
│   ├── template/           # workflow template — spec traceability skeleton
│   ├── demo_tiny_alu/       # demo — ALU spec + Python golden model
│   ├── demo_tiny_alu_subsys/     # demo — system spec + demo_tiny_alu_subsys_csr.rdl + demo_tiny_alu_subsys_model.py
│   └── demo_cdc_src_sync/  # demo — source-synchronous methodology + coverage items
├── verif/
│   ├── apb/  ip_cdc_sync/  ip_cdc_handshake/  ip_async_fifo/   # base IP suites
│   ├── template/           # workflow template — starter verification files
│   ├── demo_tiny_alu/       # demo — SV/LVM cosim suite + DV report + Surfer layout
│   ├── demo_tiny_alu_cocotb/# demo — cocotb cosim against the shared Python golden
│   ├── demo_tiny_alu_sc/   # demo — SystemC peer suite for the same ALU DUT
│   ├── demo_tiny_alu_subsys/     # demo — system-level multi-clock APB suite
│   ├── demo_cdc_src_sync/  # demo — propagation test through the A→B→C chain
│   ├── demo_abv_features/  # demo — testbench-side SVA for ABV (`rb test` --assert)
│   ├── demo_pulp_platform_axi/  # third-party — pulp-platform AXI directed + elaboration tests
│   └── demo_axi_2x2/       # demo — directed 2x2 AXI traffic testbench
├── synth/
│   ├── demo_tiny_alu/       # demo — Yosys synth of the ALU leaf (generic + Nangate45)
│   ├── demo_tiny_alu_subsys/     # demo — Yosys synth of the system block (generic + Nangate45)
│   └── demo_cdc_src_sync/  # demo — Yosys synth of the source-sync chain
├── pnr/
│   └── demo_tiny_alu_subsys/     # demo — `rb pnr` Nangate45 flow (OpenROAD)
├── fpv/
│   ├── demo_abv_basic/   # demo — `rb fpv` saturating counter (bmc + cover)
│   └── demo_abv_features/  # demo — slang-fronted `|->` properties exercising vacuity / COI / dead-assume
├── lint/
│   └── cdc/                # CDC lint configs (one entry per demo / base-IP analysis)
├── vendor/
│   └── pulp-platform/      # third-party — axi, common_cells, common_verification submodules
├── common/                 # shared SV verification helpers (LVM macros)
├── tools/                  # toolchain setup notes (yosys, yosys-slang, openroad)
└── pyproject.toml          # uv-managed project env + pinned rtl_buddy
```

## Quick Start

From the repo root, after `uv sync`:

```bash
# Spec traceability   — list spec blocks + close spec→design→coverage loop
uv run rb spec list
uv run rb spec check-design
uv run rb spec check-coverage

# Single test         — one named test in a suite
(cd verif/demo_tiny_alu && uv run rb test basic)

# Sim regression      — full suite (sanity tier + the reglvl-1000 deferred tier)
uv run rb regression -c regression.yaml -l 1000

# Coverage regression — same, with merged LCOV HTML and Coverview zip
uv run rb -M cov regression -c regression.yaml -l 1000 \
    --coverage-merge --coverage-html --coverage-coverview

# Hub UI              — landing + schematic / graph / coverage apps in the browser
uv run rb graph build                 # one-off: feeds the graph app
uv run rb hub start --serve-viewer    # then open the printed http://127.0.0.1:<port>/

# Waveform viewer     — open Surfer with the suite's signal layout
(cd verif/demo_tiny_alu && uv run rb wave basic)

# SystemC peer        — same ALU DUT driven from sc_main()
(cd verif/demo_tiny_alu_sc && uv run rb test basic_sc)

# DV report           — visualize PASS/FAIL + objective + waveform PNG per test
(cd verif/demo_tiny_alu && uv run python build_report.py)

# System-level demo   — multi-clock APB accelerator
(cd verif/demo_tiny_alu_subsys && uv run rb test csr_smoke)
(cd verif/demo_tiny_alu_subsys && uv run rb test fifo_stream)

# Regenerate PeakRDL CSRs (from spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl)
(cd design/demo_tiny_alu_subsys && ./gen_demo_tiny_alu_subsys_csr.sh)

# CDC lint regression — clock-domain-crossing checks across all configured analyses
uv run rb cdc-regression -c lint/cdc/cdc_regression.yaml

# AXI traffic demo    — directed 2x2 crossbar traffic for waveform/profiler work
(cd verif/demo_axi_2x2 && uv run rb test basic_traffic)

# Synth regression    — generic synth runs (tech-mapped is gated by reglvl)
uv run rb synth-regression -c synth_regression.yaml

# FPV regression      — SymbiYosys proofs for every suite in fpv_regression.yaml
uv run rb fpv-regression
```

Each section below walks through *what* the feature does, *how it is
wired*, and where to look for a working example.

---

## Spec Traceability — `rb spec`

`rb spec` formalises the link from human-readable spec → executable
golden model → SV functional coverage → test plan. Drift in any
direction shows up as a missing item rather than going unnoticed.

### How it is wired

- **Block definition**: each `spec/<block>/specs.yaml` declares the
  block name, prose docs, and a list of `coverage-items` with stable
  IDs (e.g. `SAND-FUNC-OP-ADD`, `ACCEL-CSR-DIRECT-OP`).
- **Prose spec**: `spec/<block>/README.md` is the human-readable
  source of truth — interface, behaviour, edge cases.
- **Executable golden model** (where applicable):
  [`spec/demo_tiny_alu/tiny_alu_model.py`](spec/demo_tiny_alu/tiny_alu_model.py) is
  the Python form of the alu spec, consumed live by the cocotb suite
  and offline by `verif/demo_tiny_alu/preproc.py` to generate the SV
  testbench's stimulus + expected results.
- **Design link**: each `design/<block>/models.yaml` carries
  `spec: "../../spec/<block>/specs.yaml"` so `rb spec check-design`
  verifies every block has a model.
- **Coverage labels**: SV cover-property labels in
  `verif/<block>/cov_*.sv` (and equivalents) match the spec IDs.
- **Test → coverage**: each test in `verif/<block>/tests.yaml`
  declares a `covers:` list of the IDs it targets.

### Try it

```bash
uv run rb spec list             # 8 blocks (47 coverage IDs total)
uv run rb spec check-design     # every block points at a design model
uv run rb spec check-coverage   # every coverage ID is referenced by a test
```

A failing `check-coverage` row means an ID exists in `specs.yaml` but
no test references it — typically a missing `tests.yaml: covers:`
entry, or a label drift between spec and coverage source.

---

## Tests — `rb test`

A single test runs the compile + sim of one named entry from a
suite-local `tests.yaml`. Use this for local debug, before promoting
work to a regression.

### How it is wired

- **Suite layout**: a verif suite is a directory containing
  `tests.yaml` plus its testbenches / cocotb modules.
- **`tests.yaml`** declares two top-level lists:
  - `testbenches:` — name, filelist, optional `toplevel:` and
    `cocotb:` block (for cocotb-driven flows)
  - `tests:` — per-test `name`, `desc`, `reglvl`, `plusargs`,
    `plusdefines`, `model:` + `model_path:`, `testbench:`, `covers:`
- **Models**: each `design/<block>/models.yaml` maps a model name to
  a filelist (`-F file.f` allowed). The testbench wraps that with its
  own files.
- **Builder modes**: `-M debug` (default) compiles with FST trace and
  full assertions. `-M reg` strips trace for speed. `-M cov` adds
  Verilator coverage. Modes are defined in
  [`root_config.yaml`](root_config.yaml).

### Try it

```bash
# leaf-IP smoke
(cd verif/ip_cdc_handshake && uv run rb test smoke)

# SV/LVM ALU, single test
(cd verif/demo_tiny_alu && uv run rb test basic)

# cocotb peer suite — same DUT, Python-driven, scoreboarded against shared golden
(cd verif/demo_tiny_alu_cocotb && uv run rb test cocotb_random)

# SystemC peer suite — same DUT, C++-driven through sc_main()
(cd verif/demo_tiny_alu_sc && uv run rb test basic_sc)

# system-level (multi-clock APB)
(cd verif/demo_tiny_alu_subsys && uv run rb test csr_smoke)

# AXI traffic demo — directed 2x2 crossbar traffic
(cd verif/demo_axi_2x2 && uv run rb test basic_traffic)

# regression-mode run for speed
(cd verif/demo_tiny_alu && uv run rb -M reg test random)
```

Per-test artefacts land at `<suite>/artefacts/<test>/` (gitignored).
The SV/LVM `demo_tiny_alu` testbench writes a transaction log
(`txn.log`) used later by the DV report.

---

## Regression — `rb regression`

Runs every test listed in a regression config across one or more
suites, with reglvl filtering, summary tables, and machine-readable
output for CI.

### How it is wired

- **Top-level config**: [`regression.yaml`](regression.yaml) lists
  each suite's `tests.yaml`, covering the 4 base-IP suites plus the
  `demo_tiny_alu`, `demo_tiny_alu_cocotb`, `demo_tiny_alu_sc`,
  `demo_tiny_alu_subsys`, `demo_cdc_src_sync`,
  `demo_pulp_platform_axi`, and `demo_axi_2x2` demos.
- **Reglvl gating**: each test in `tests.yaml` has a `reglvl`
  (0 = always run, larger = deferred tiers, 10000 = disabled).
  `--reg-level N` (alias `-l`) caps the run.
- **Pointer in `root_config.yaml`**: `cfg-rtl-reg.reg-cfg-path` is
  the default config path so `rb regression` (no `-c`) just works
  from the repo root.
- **Machine mode**: `--machine` switches the renderer to JSON Lines
  for CI (used by `.github/workflows/verilator.yml`).

### Try it

```bash
uv run rb regression -c regression.yaml             # sanity tier only (reglvl 0, the -l default) — per-push CI
uv run rb regression -c regression.yaml -l 1000     # full suite (sanity + reglvl-1000 deferred tier) — nightly
uv run rb --machine regression -c regression.yaml   # CI-style JSON output
```

---

## Third-Party IP — vendoring `pulp-platform/axi`

The `demo_pulp_platform_axi` block shows how to integrate external
SystemVerilog IP into an `rtl_buddy` project without giving up Verilator
lint hygiene on your own RTL. It pulls in the
[`pulp-platform/axi`](https://github.com/pulp-platform/axi) interconnect
(plus `common_cells` and `common_verification`) as git submodules,
under `vendor/pulp-platform/`.

### How it is wired

- **Submodules**: `vendor/pulp-platform/{axi,common_cells,common_verification}`
  pinned via `.gitmodules`. CI checks out with `submodules: recursive`.
- **Curated filelists**:
  [`design/demo_pulp_platform_axi/pp_axi.f`](design/demo_pulp_platform_axi/pp_axi.f) +
  [`axi_common_cells.f`](design/demo_pulp_platform_axi/axi_common_cells.f) are
  Bender-style compile-ordered filelists — only the 25 common_cells
  primitives needed by `axi`, dependency-level ordered, with no
  `tech_cells_generic`.
- **Scoped lint waivers**:
  [`pp_axi.vlt`](design/demo_pulp_platform_axi/pp_axi.vlt) restricts vendor-only
  waivers (GENUNNAMED, SYNCASYNCNET, UNDRIVEN, ASCRANGE, UNOPTFLAT,
  UNSIGNED, IMPLICIT) to `*/pulp-platform/*`. Your own RTL stays under
  full lint.
- **Tests**:
  [`tb_axi_fifo_simple.sv`](verif/demo_pulp_platform_axi/tb_axi_fifo_simple.sv)
  is a directed Verilator-friendly test of `axi_fifo_intf`;
  [`tb_top.sv`](verif/demo_pulp_platform_axi/tb_top.sv) is an elaboration-only
  wrapper for vendor `axi_synth_bench`, with `plusdefines: SYNTHESIS=1`
  silencing vendor sim-only `$fatal` assumptions at t=0.

### Try it

```bash
git submodule update --init --recursive          # once after clone

(cd verif/demo_pulp_platform_axi && uv run rb test axi_fifo_simple)
(cd verif/demo_pulp_platform_axi && uv run rb test synth_bench)
```

See [`design/demo_pulp_platform_axi/README.md`](design/demo_pulp_platform_axi/README.md)
for details on the Verilator limitation that excludes the vendor OOP
`tb_axi_fifo` test from this template's flow.

---

## Coverage + Coverview — `rb -M cov regression …`

Verilator coverage collection, merge, LCOV HTML export, and packaging
into a Coverview zip for the browser dashboard.

### How it is wired

- **Builder mode**: `-M cov` selects the `cov` block in
  `cfg-rtl-builder` (extra `--coverage-line/-toggle/-expr/-user`
  flags).
- **Per-regression merge**: `--coverage-merge` collects coverage
  across the whole regression into `cov_dir/coverage_merged.{dat,info}`.
- **HTML export**: `--coverage-html` runs LCOV → `coverage_merge.html`.
- **Coverview zip**: `--coverage-coverview` uses the `info-process`
  package (declared in `pyproject.toml`) to package the merged data
  into `coverview_regression.zip` per [`coverview.md`](coverview.md).
- **Coverview config**: `cfg-coverview` in `root_config.yaml`
  controls the dashboard title and table type.
- **Loop with spec**: `tests.yaml` `covers:` IDs are listed in the
  generated DV report and validated by `rb spec check-coverage`.

### Try it

```bash
uv run rb -M cov regression -c regression.yaml -l 1000 \
    --coverage-merge --coverage-html --coverage-coverview
# Outputs land at the directory you run from. From repo root:
open coverage_merge.html
```

When invoked from a suite directory the merged artefacts land in
that suite instead. Coverview viewer setup: see
[`coverview.md`](coverview.md).

The `verilator-coverage` job in
[`.github/workflows/verilator.yml`](.github/workflows/verilator.yml)
runs the same `-M cov regression --coverage-merge --coverage-html` on
every push and uploads the merged HTML report (`coverage-html`) and
LCOV data (`coverage-data`) as workflow artifacts, so browsing
coverage from a PR is one download away.

---

## Hub UI — `rb hub start --serve-viewer`

`rtl_buddy` ships a browser UI family served by the project hub: a
landing page at `/` that lists the apps by task, and three apps —
**rtl-buddy-schematic** (`sch`, at `/view`), **rtl-buddy-graph**
(`gph`, at `/graph`), and **rtl-buddy-coverage** (`cov`, at `/cov`).
All three share one design-token sheet (light default, dark via your
OS preference), one connection-status strip, and one
`rtl-buddy <version> @ <sha>` label — and they talk to each other
live through the hub.

### How it is wired

- `rb hub start --serve-viewer` starts the project hub (one per
  project directory, discovered via `.rtl-buddy/hub.json`) and serves
  the UI on the printed `http_port`. The schematic SPA is
  auto-discovered from the installed `rtl-buddy-view` wheel — no npm,
  no build step, nothing off localhost.
- The landing greys out an app whose data is missing and names the
  command that produces it: the graph app wants `rb graph build`, the
  coverage app wants a coverage-flagged regression (its model is read
  straight off the artefacts on disk — no export step).
- Each app is a hub peer with its own origin, so all three can be
  open at once. Selections cross-link: clicking a module in the graph
  or coverage selects its instance in the schematic, every app
  carries `send → sch / gph / cov / editor` actions, and
  `rb hub send` (or the MCP hub tools) drives the same vocabulary
  from the CLI and agents.
- The schematic adds a hierarchy tree with filter (`/`), live
  coverage tint from the same model the coverage app reads,
  double-click descend, and Esc/`u` keyboard navigation.

### Try it

```bash
uv run rb graph build          # feed the graph app (re-run after design changes)
uv run rb -M cov regression -c regression.yaml -l 1000 \
    --coverage-merge           # feed the coverage app
uv run rb hub start --serve-viewer
# open the printed http://127.0.0.1:<http_port>/ and pick an app
uv run rb hub status           # peers + ports at a glance
```

---

## Golden-Model Cosim — One Spec, Two Flows

The `demo_tiny_alu` blocks prove a single Python golden
([`spec/demo_tiny_alu/tiny_alu_model.py`](spec/demo_tiny_alu/tiny_alu_model.py))
against the same DUT from two independent verif suites. Drift in
either direction surfaces immediately.

### SV/LVM side (`verif/demo_tiny_alu/`) — preproc-driven

- [`preproc.py`](verif/demo_tiny_alu/preproc.py) is wired as the test's
  `preproc:` plugin. Before compile, it picks a stimulus sequence
  (basic / ops_sweep / flags / random), expands it through
  `tiny_alu_model.AluModel.compute()`, and writes
  `<artefacts>/<test>/vectors.txt` containing one row per cycle:
  `op, a, b, y, zf, cf, nf, vf` (the trailing five are the expected
  registered DUT outputs, computed by the Python golden).
- The absolute path to `vectors.txt` is injected back into the
  test's plusargs as `VECTORS=`.
- [`tb_top.sv`](verif/demo_tiny_alu/tb_top.sv) reads `vectors.txt`, drives
  one `(op,a,b)` per clock, and compares the registered DUT output
  to the expected on the cycle the result lands. Mismatches bump LVM
  `nerr` → FAIL.
- There is **no** inline SV reference any more — the Python golden is
  the single source of truth, consumed offline via preproc.

### cocotb side (`verif/demo_tiny_alu_cocotb/`) — live

- Pure cocotb against `toplevel: alu` — no SV testbench wrapper. The
  shared helpers in
  [`_alu_common.py`](verif/demo_tiny_alu_cocotb/_alu_common.py) import
  `tiny_alu_model.AluModel` directly and scoreboard live every cycle.
- Two test modules
  ([`test_alu_random.py`](verif/demo_tiny_alu_cocotb/test_alu_random.py),
   [`test_alu_flags.py`](verif/demo_tiny_alu_cocotb/test_alu_flags.py)) so
  rtl_buddy test selection maps cleanly to cocotb tests.

### Try it

```bash
(cd verif/demo_tiny_alu        && uv run rb test random)           # SV (preproc + sim)
(cd verif/demo_tiny_alu_cocotb && uv run rb test cocotb_random)    # cocotb (live)
```

Both pass with **zero** mismatches. Break either side (mutate
`AluModel.compute` in `tiny_alu_model.py`, or break the alu RTL) and
the corresponding flow fails loudly.

---

## Surfer Waveforms — `rb wave`

`rb wave` opens the [Surfer](https://surfer-project.org/) waveform
viewer for a test's FST and connects it to your editor via WCP, so
right-clicking a signal jumps to its declaration with inline value
annotation at the cursor timestamp.

### How it is wired

- **Tool config**: `cfg-surfer` in
  [`root_config.yaml`](root_config.yaml) declares the surfer binary
  path (`"surfer"` resolves via `$PATH`).
- **Per-suite layout**: each suite ships a `tb_top.surfer` command
  file (groups, dividers, signal list, zoom_fit). `rb wave <test>`
  autoloads `<test>.surfer` if present, else `tb_top.surfer`.
- **Headless capture**: the same command file is also used by the DV
  report builder to render PNGs in `--headless --exit-after-commands`
  mode.

### Try it

```bash
(cd verif/demo_tiny_alu    && uv run rb test basic)        # produce FST first
(cd verif/demo_tiny_alu    && uv run rb wave basic)        # open Surfer
(cd verif/demo_tiny_alu_subsys  && uv run rb wave csr_smoke)    # multi-clock layout
```

---

## DV Report — Test Outcomes Visualized

[`verif/demo_tiny_alu/build_report.py`](verif/demo_tiny_alu/build_report.py) is a
post-run *visualization* step. It does not re-check correctness —
the simulator already did, against the preproc-generated expected
results. The report turns each test's artefacts into a markdown
summary tying test outcome to declared objective with a waveform
snapshot for evidence.

### What it produces

For each test in the `verif/demo_tiny_alu` suite:
- **`report/<test>.md`** — declared objective (from `tests.yaml`
  `desc:`), declared `covers:` IDs, PASS/FAIL pulled from
  `<artefacts>/<test>/test.log`, embedded waveform PNG, FST path,
  `test.log` tail.
- **`report/<test>.png`** — Surfer headless capture using the shared
  `tb_top.surfer` layout with `export_wave` appended.
- **`report/index.md`** — roll-up table linking every test report.

### How it is wired

- Reads PASS/FAIL from each test's `test.log` (`PASS (nwrn=…)` /
  `FAIL (nerr=…)`).
- Appends `export_wave report/<test>.png 1600 600` to the surfer
  command file and runs `surfer --headless -c <cmd> dump.fst`.
- Falls back gracefully when surfer isn't on `PATH` — the report
  still lists FST path + status + log tail.

### Try it

```bash
(cd verif/demo_tiny_alu && uv run rb -M debug regression -c ../../regression.yaml)
(cd verif/demo_tiny_alu && uv run python build_report.py)
open verif/demo_tiny_alu/report/index.md
```

---

## PeakRDL Register Generation

The `demo_tiny_alu_subsys` CSR block is generated from a SystemRDL description
([`spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl`](spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl))
using [PeakRDL-regblock](https://peakrdl-regblock.readthedocs.io/).
The generated SV files are committed; CI runs the regen script and
`git diff --exit-code` to catch drift.

### How it is wired

- **Source of truth**: `spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl` lives with
  the spec, not the design. Edit this when register layout changes.
- **Regen script**:
  [`design/demo_tiny_alu_subsys/gen_demo_tiny_alu_subsys_csr.sh`](design/demo_tiny_alu_subsys/gen_demo_tiny_alu_subsys_csr.sh)
  invokes `peakrdl regblock` with `--cpuif apb4-flat
  --default-reset rst_n` and patches in Verilator-friendly lint
  waivers on the generated files.
- **Output**: `demo_tiny_alu_subsys_csr.sv` + `demo_tiny_alu_subsys_csr_pkg.sv` in
  `design/demo_tiny_alu_subsys/`. Both are committed.
- **Pinned deps**: `peakrdl` and `peakrdl-regblock` come from the
  rtl-buddy fork via `[tool.uv.sources]` in `pyproject.toml`.
- **Hwif wiring**:
  [`design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_top.sv`](design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_top.sv)
  consumes the generated `hwif_in`/`hwif_out` structs and threads
  them to the compute domain through `ip_cdc_handshake` /
  `ip_async_fifo`.

### Try it

```bash
# Edit spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl, then:
(cd design/demo_tiny_alu_subsys && ./gen_demo_tiny_alu_subsys_csr.sh)

# Regression catches any RTL drift (demo_tiny_alu_subsys is in the
# reglvl-1000 tier, so use -l 1000):
uv run rb regression -c regression.yaml -l 1000
```

---

## CDC Lint — `rb cdc` / `rb cdc-regression`

Static clock-domain-crossing checks driven by an SDC per analysis,
with optional waivers. Same shape as the sim/synth flows: a
`cdc.yaml` per directory enumerating analyses, an optional
`cdc_regression.yaml` discoverable list, and tool defaults in
`root_config.yaml`.

### How it is wired

- **CDC config**: [`lint/cdc/cdc.yaml`](lint/cdc/cdc.yaml) declares
  one entry per analysis with `name`, `model`, `model_path:` pointer
  into `design/.../models.yaml`, `tool:`, an SDC `constraints:` file,
  and an optional `waivers:` file. Three analyses today:
  - `ip_cdc_handshake_lint` — the request/ack handshake IP
  - `demo_tiny_alu_subsys_lint` — the multi-clock APB↔compute system
    (uses [`demo_tiny_alu_subsys.waivers`](lint/cdc/demo_tiny_alu_subsys.waivers))
  - `demo_cdc_src_sync_lint` — the source-synchronous A→B→C chain;
    relies on internal-pin `create_generated_clock` declarations
- **Tool defaults**: `cfg-cdc-tools` in
  [`root_config.yaml`](root_config.yaml) defines the `rtl-buddy-cdc`
  entry and its options (default `sync-depth: 2`). `tool:` in
  `cdc.yaml` selects the entry.
- **Discoverable regression**:
  [`lint/cdc/cdc_regression.yaml`](lint/cdc/cdc_regression.yaml)
  drives `rb cdc-regression` across all listed `cdc.yaml` files.

### Try it

```bash
# list the configured analyses
uv run rb cdc --list -c lint/cdc/cdc.yaml

# run one analysis by name
uv run rb cdc ip_cdc_handshake_lint -c lint/cdc/cdc.yaml

# run everything in this cdc.yaml
uv run rb cdc -c lint/cdc/cdc.yaml

# discoverable regression — every cdc.yaml in cdc_regression.yaml
uv run rb cdc-regression -c lint/cdc/cdc_regression.yaml
```

---

## Synthesis — `rb synth` / `rb synth-regression`

Tool-agnostic Yosys synthesis with optional technology mapping
against a Liberty file. Same shape as the sim flow: `synth.yaml` per
block, an optional `synth_regression.yaml` discoverable list, and
tool defaults in `root_config.yaml`.

### How it is wired

- **Synthesis config**:
  [`synth/demo_tiny_alu/synth.yaml`](synth/demo_tiny_alu/synth.yaml) defines two
  runs:
  - `demo_tiny_alu_synth_generic` — tech-independent, `reglvl: 0` (default).
  - `demo_tiny_alu_synth_nangate45` — tech-mapped to Nangate45 typical corner,
    `reglvl: 1000` (deferred until the PDK is fetched).
  [`synth/demo_tiny_alu_subsys/synth.yaml`](synth/demo_tiny_alu_subsys/synth.yaml) adds the
  whole-system run `demo_tiny_alu_subsys_synth_generic`.
- **Constraints**:
  [`synth/demo_tiny_alu/constraints.sdc`](synth/demo_tiny_alu/constraints.sdc)
  carries a 100 MHz `create_clock`. Yosys extracts the period and
  passes it to ABC for timing-driven mapping; the critical path
  becomes WNS in the results table.
- **Tool defaults**: `cfg-synth-tools` (yosys) and `cfg-synth-libs`
  (`nangate45_typ`) in [`root_config.yaml`](root_config.yaml).
- **PDK download**:
  [`synth/demo_tiny_alu/download_pdk.sh`](synth/demo_tiny_alu/download_pdk.sh)
  fetches the Nangate45 Liberty from OpenROAD-flow-scripts (~6 MB).
  `pdk/` is gitignored.
- **Flat-port wrapper for the system**:
  [`design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_synth_top.sv`](design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_synth_top.sv)
  flattens the APB SV interface so Yosys can elaborate the top.
- **Discoverable regression**:
  [`synth_regression.yaml`](synth_regression.yaml) drives
  `rb synth-regression` across all listed `synth.yaml` files.

### Try it

```bash
# tech-independent — no PDK needed
uv run rb synth demo_tiny_alu_synth_generic       -c synth/demo_tiny_alu/synth.yaml
uv run rb synth demo_tiny_alu_subsys_synth_generic -c synth/demo_tiny_alu_subsys/synth.yaml

# tech-mapped — Nangate45 Liberty for the alu leaf
./synth/demo_tiny_alu/download_pdk.sh
uv run rb synth demo_tiny_alu_synth_nangate45 -c synth/demo_tiny_alu/synth.yaml

# tech-mapped — Nangate45 Liberty for the full system block
./synth/demo_tiny_alu_subsys/download_pdk.sh
uv run rb synth demo_tiny_alu_subsys_synth_nangate45 -c synth/demo_tiny_alu_subsys/synth.yaml

# discoverable regression — generic by default; bump -l to include nangate45
uv run rb synth-regression -c synth_regression.yaml
uv run rb synth-regression -c synth_regression.yaml -l 1000
```

The tech-mapped run reports gate count, area (µm²), and worst-negative
slack against the SDC.

## Physical Implementation

`rb pnr` takes the tech-mapped `demo_tiny_alu_subsys` netlist through
floorplan, placement, CTS, routing, and (optionally) GDS streamout +
PNG rendering via KLayout. Driven by `pnr/demo_tiny_alu_subsys/pnr.yaml`:

```bash
# Liberty + LEF + cell GDS
./synth/demo_tiny_alu_subsys/download_pdk.sh

# tech-mapped synth (if not already done)
uv run rb synth demo_tiny_alu_subsys_synth_nangate45 \
    -c synth/demo_tiny_alu_subsys/synth.yaml

# place + route — outputs routed DEF, post-route netlist, timing report
uv run rb pnr demo_tiny_alu_subsys_pnr_nangate45 \
    -c pnr/demo_tiny_alu_subsys/pnr.yaml -l 1000

# add --gds --png to stream out GDS + render PNG via KLayout
```

Outputs land in `pnr/demo_tiny_alu_subsys/artefacts/<run>/`. Requires a
local `openroad` build (referenced via `cfg-pnr-tools` if outside PATH);
KLayout is optional and only needed for `--gds`/`--png`.

---

## The `demo_tiny_alu_subsys` System Block

How the leaf IPs compose into the system demonstrator.

### Clock domains

- `apb_clk` — APB host bus and the PeakRDL-generated CSR block
- `cclk`    — compute domain (drives the `alu`)
- both also serve as the write/read clocks of `ip_async_fifo` for
  streaming-input mode

### CDC paths

- **CSR-direct mode** — `ip_cdc_handshake` carries `{op,a,b}` from
  the APB domain to compute when SW writes `ctrl.GO=1`.
- **FIFO-stream mode** — `ip_async_fifo` accepts records pushed via
  `fifo_push` register writes; compute drains at its own rate when
  `ctrl.SRC=1`.
- Results return to APB through a second `ip_cdc_handshake`; status
  flags (`BUSY`, `FIFO_FULL`, `FIFO_EMPTY`) are gathered through
  `ip_cdc_sync` chains so software can poll them from the APB side.

### Software protocol summary

```
# CSR-direct
write op.OP, operand_a.A, operand_b.B
write ctrl.GO=1
poll  status.BUSY=0
read  result.Y, flags.{ZF,CF,NF,VF}

# FIFO stream
write ctrl.SRC=1
loop: poll status.FIFO_FULL=0; write fifo_push={PUSH=1,OP,A,B}
poll  status.FIFO_EMPTY=1 && status.BUSY=0
read  result.Y, flags.*
```

See [`spec/demo_tiny_alu_subsys/README.md`](spec/demo_tiny_alu_subsys/README.md) for the
full register map and behaviour, and
[`verif/demo_tiny_alu_subsys/testplan.md`](verif/demo_tiny_alu_subsys/testplan.md) for the
test → coverage mapping.

```bash
(cd verif/demo_tiny_alu_subsys && uv run rb test csr_smoke)     # CSR-direct
(cd verif/demo_tiny_alu_subsys && uv run rb test fifo_stream)   # FIFO mode (drives FULL + DRAIN)
uv run rb synth demo_tiny_alu_subsys_synth_generic -c synth/demo_tiny_alu_subsys/synth.yaml
```

---

## Building Your Own Project From This Template

Typical next steps:

- Add real blocks alongside the existing ones (or replace the demo
  ones once you've internalised the patterns).
- Use [`spec/template/`](spec/template/),
  [`design/template/`](design/template/), and
  [`verif/template/`](verif/template/) as boilerplate copies for a
  new block.
- Update [`root_config.yaml`](root_config.yaml) with your preferred
  builders, flags, and tool entries.
- Expand [`regression.yaml`](regression.yaml) and
  [`synth_regression.yaml`](synth_regression.yaml) to include your
  real suites.
- If your project uses formal verification, add `fpv/` suites plus
  matching `cfg-fpv-tools` entries and regression wiring.
- Rewrite the repo docs ([`README.md`](README.md),
  [`AGENTS.md`](AGENTS.md)) so they describe your project instead of
  the template.

An AI agent can also follow the instructions in
[`AGENTS.md`](AGENTS.md) to help adapt this template into your
project.