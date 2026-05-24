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
and formal property verification — so the mechanics stay in focus
instead of the DUT.

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
| `demo_tiny_alu_sc`      | SystemC + Verilator cosim peer of `demo_tiny_alu`, suitable for C++ / TLM-style harnesses | [`verif/demo_tiny_alu_sc/`](verif/demo_tiny_alu_sc/) |
| `demo_tiny_alu_subsys`      | Multi-clock APB-mapped ALU accelerator that composes apb + ip_cdc_* + ALU; also drives the `rb pnr` Nangate45 flow | [`design/demo_tiny_alu_subsys/`](design/demo_tiny_alu_subsys/), [`spec/demo_tiny_alu_subsys/`](spec/demo_tiny_alu_subsys/), [`verif/demo_tiny_alu_subsys/`](verif/demo_tiny_alu_subsys/), [`pnr/demo_tiny_alu_subsys/`](pnr/demo_tiny_alu_subsys/) |
| `demo_cdc_src_sync`   | Source-synchronous chain (A→B0/B1→C0/C1) exercising internal-pin `create_generated_clock` for SoC-scope CDC | [`design/demo_cdc_src_sync/`](design/demo_cdc_src_sync/), [`spec/demo_cdc_src_sync/`](spec/demo_cdc_src_sync/), [`verif/demo_cdc_src_sync/`](verif/demo_cdc_src_sync/) |
| `demo_fpv_counter`    | Saturating up-counter with a bound SVA checker for `rb fpv` (bmc-proves no-overflow, cover-reaches saturation) | [`design/demo_fpv_counter/`](design/demo_fpv_counter/), [`fpv/demo_fpv_counter/`](fpv/demo_fpv_counter/) |

### Third-party IP

| IP                  | What it shows                                                                                       | Paths                                                                                                                            |
|---------------------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| `demo_pulp_platform_axi` | Vendoring third-party SV IP — pulp-platform AXI interconnect via git submodules, with a curated filelist, scoped Verilator lint waivers, a directed FIFO testbench, and an elaboration sweep across all adapter variants | [`design/demo_pulp_platform_axi/`](design/demo_pulp_platform_axi/), [`verif/demo_pulp_platform_axi/`](verif/demo_pulp_platform_axi/), [`vendor/pulp-platform/`](vendor/pulp-platform/) |

With the documented optional tools installed, `rb regression -c regression.yaml`
exercises the base-IP suites plus the SV/LVM, cocotb, SystemC, subsystem,
source-sync, and vendored-AXI demos; `rb synth-regression -c synth_regression.yaml`
synthesizes the alu leaf, the full system, and the source-sync chain; and
`rb fpv-regression` proves the counter demo's never-overflow invariant and
reaches the saturated state via SymbiYosys + yices.

## Tooling Scope

`rtl_buddy` adapts to the toolchain your project already uses. In this
template the supported flows are:

- **Verilator** for the open-source compile/sim/regression/coverage path
- **VCS** for teams using Synopsys flows
- **Yosys** (rtl-buddy fork) for synthesis (generic + tech-mapped)
- **rtl-buddy-cdc** for `rb cdc` clock-domain-crossing lint
- **OpenROAD** for `rb pnr` (floorplan → P&R → optional GDSII streamout); KLayout for GDS rendering
- **cocotb** for Python-driven testbenches
- **SystemC + Verilator cosim** for C++ / TLM-style harnesses via `rb test`
- **Surfer** + WCP for live waveform viewing and headless capture
- **Coverview** for browser-based coverage dashboards
- **PeakRDL** for SystemRDL → SystemVerilog register block generation
- **SymbiYosys (`sby`)** for `rb fpv` formal property verification — the `demo_fpv_counter` block + `fpv_regression.yaml` exercise the flow end-to-end

## Setup

External prerequisites:

- `uv`, Python 3.11
- A simulator on `PATH` — Verilator (open-source) and/or VCS
- `lcov` for LCOV/HTML coverage export — `brew install lcov` on macOS; `apt-get install lcov` on Debian/Ubuntu (needed for the `--coverage-html` step of `rb -M cov regression`)
- `coverview` (Antmicro) for the Coverview package path — see [`coverview.md`](coverview.md)
- Verible — `brew tap chipsalliance/verible && brew install verible` on macOS (optional, for `rb verible …`)
- Yosys — build the [rtl-buddy fork](https://github.com/rtl-buddy/yosys) onto `PATH` (optional, for `rb synth …`); macOS notes in [`tools/yosys/SETUP_OSX.md`](tools/yosys/SETUP_OSX.md)
- yosys-slang — build the [yosys-slang plugin](https://github.com/povik/yosys-slang) (optional; only if any synth or CDC analysis sets `frontend: "slang"` for SV-2017 designs the built-in Yosys frontend rejects); macOS notes in [`tools/yosys-slang/SETUP_OSX.md`](tools/yosys-slang/SETUP_OSX.md)
- OpenROAD — build from source onto `PATH` (optional, for downstream P&R; macOS notes in [`tools/openroad/SETUP_OSX.md`](tools/openroad/SETUP_OSX.md))
- Surfer — build from the [rtl-buddy fork](https://github.com/rtl-buddy/surfer) onto `PATH` (optional, for `rb wave` and headless waveform capture)
- SystemC (Accellera reference distribution) — optional, only for `verif/demo_tiny_alu_sc/`; export `SYSTEMC_HOME` or override `cfg-systemc.home`, and keep the compiler ABI aligned with the SystemC build. See [`verif/demo_tiny_alu_sc/README.md`](verif/demo_tiny_alu_sc/README.md) for the platform-specific notes
- SymbiYosys (`sby`) plus a solver such as `yices`, `z3`, or `boolector` — required to run `demo_fpv_counter` and any `rb fpv …` suites; macOS: `brew install yices2` covers the solver, see [the FPV concept doc](https://rtl-buddy.github.io/rtl_buddy/latest/concepts/fpv/) for sby install

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
│   ├── demo_tiny_alu_subsys/     # demo — PeakRDL CSR + multi-clock top + compute wrapper
│   ├── demo_cdc_src_sync/  # demo — source-synchronous CDC reference (internal-pin clock forwarding)
│   ├── demo_fpv_counter/   # demo — saturating counter exercised by `rb fpv`
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
│   ├── demo_tiny_alu_subsys/     # demo — system-level multi-clock APB suite
│   ├── demo_tiny_alu_sc/    # demo — SystemC + Verilator cosim peer of demo_tiny_alu
│   ├── demo_cdc_src_sync/  # demo — propagation test through the A→B→C chain
│   └── demo_pulp_platform_axi/  # third-party — pulp-platform AXI directed + elaboration tests
├── synth/
│   ├── demo_tiny_alu/       # demo — Yosys synth of the ALU leaf (generic + Nangate45)
│   ├── demo_tiny_alu_subsys/     # demo — Yosys synth of the system block (generic + Nangate45)
│   └── demo_cdc_src_sync/  # demo — Yosys synth of the source-sync chain
├── pnr/
│   └── demo_tiny_alu_subsys/     # demo — `rb pnr` Nangate45 flow (OpenROAD)
├── fpv/
│   └── demo_fpv_counter/   # demo — `rb fpv` saturating counter (bmc + cover)
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

# Sim regression      — every suite listed in regression.yaml
uv run rb regression -c regression.yaml

# Coverage regression — same, with merged LCOV HTML and Coverview zip
uv run rb -M cov regression -c regression.yaml \
    --coverage-merge --coverage-html --coverage-coverview

# Waveform viewer     — open Surfer with the suite's signal layout
(cd verif/demo_tiny_alu && uv run rb wave basic)

# DV report           — visualize PASS/FAIL + objective + waveform PNG per test
(cd verif/demo_tiny_alu && uv run python build_report.py)

# SystemC peer demo   — same ALU DUT, C++ / Verilator cosim
(cd verif/demo_tiny_alu_sc && uv run rb test basic_sc)

# System-level demo   — multi-clock APB accelerator
(cd verif/demo_tiny_alu_subsys && uv run rb test csr_smoke)
(cd verif/demo_tiny_alu_subsys && uv run rb test fifo_stream)

# Regenerate PeakRDL CSRs (from spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_csr.rdl)
(cd design/demo_tiny_alu_subsys && ./gen_demo_tiny_alu_subsys_csr.sh)

# CDC lint regression — clock-domain-crossing checks across all configured analyses
uv run rb cdc-regression -c lint/cdc/cdc_regression.yaml

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
  - `testbenches:` — name, filelist, optional `toplevel:`, `cocotb:`,
    or `systemc:` block (for alternate harnesses)
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

# SystemC peer suite — same DUT, C++-driven through Verilator's --sc flow
(cd verif/demo_tiny_alu_sc && uv run rb test basic_sc)

# system-level (multi-clock APB)
(cd verif/demo_tiny_alu_subsys && uv run rb test csr_smoke)

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
  each suite's `tests.yaml` (4 base-IP suites plus the `demo_tiny_alu`,
  `demo_tiny_alu_cocotb`, `demo_tiny_alu_sc`, `demo_tiny_alu_subsys`,
  `demo_cdc_src_sync`, and `demo_pulp_platform_axi` demos).
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
uv run rb regression -c regression.yaml             # every configured suite
uv run rb regression -c regression.yaml -l 0        # only reglvl 0 entries
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
uv run rb -M cov regression -c regression.yaml \
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

## Golden-Model Cosim — One Spec, Three Flows

The `demo_tiny_alu` blocks prove a single Python golden
([`spec/demo_tiny_alu/tiny_alu_model.py`](spec/demo_tiny_alu/tiny_alu_model.py))
against the same DUT from three independent verif suites. Drift in
any direction surfaces immediately.

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

### SystemC side (`verif/demo_tiny_alu_sc/`) — C++ harness

- [`sc_main.cpp`](verif/demo_tiny_alu_sc/sc_main.cpp) instantiates the
  Verilator-generated `Vdemo_tiny_alu` as an `sc_module`, drives it
  through `sc_signal<uint32_t>` ports, and self-checks eight directed
  opcode vectors in C++.
- `tests.yaml` uses a nested `systemc:` block to flip `rb test` into
  Verilator's `--sc --exe --build` path, parallel to how `cocotb:`
  selects the Python harness path.
- [`verif/demo_tiny_alu_sc/README.md`](verif/demo_tiny_alu_sc/README.md)
  documents the SystemC install, ABI, and `$SYSTEMC_HOME` expectations.

### Try it

```bash
(cd verif/demo_tiny_alu        && uv run rb test random)           # SV (preproc + sim)
(cd verif/demo_tiny_alu_cocotb && uv run rb test cocotb_random)    # cocotb (live)
(cd verif/demo_tiny_alu_sc     && uv run rb test basic_sc)         # SystemC (C++ / Verilator cosim)
```

All three pass with **zero** mismatches. Break either side (mutate
`AluModel.compute` in `tiny_alu_model.py`, or break the alu RTL) and
the corresponding flow fails loudly.
