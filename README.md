# RTL-Buddy Project Template

Starter RTL project to use [`rtl_buddy`](https://github.com/rtl-buddy/rtl_buddy).

A clean starting point that ships a runnable, end-to-end demonstrator
**built up from small components**. Each leaf IP (APB interface, two
CDC primitives, an async FIFO, a tiny ALU) has its own spec, testplan,
and runnable test. They compose into a multi-clock APB-mapped ALU
accelerator with PeakRDL-generated CSRs (`alu_accel`).

Together they exercise every headline `rtl_buddy` capability — spec
traceability, test, regression, coverage, golden-model cosim (SV +
cocotb), `rb wave` + headless Surfer captures, DV reports, PeakRDL
register generation, and Yosys synthesis — so the mechanics stay in
focus instead of the DUT.

## Demonstrator at a Glance

Each block has spec / design / verif under a peer subdirectory. Leaf
IPs are tested in isolation; `alu_accel` proves they compose.

| IP / Block         | Role                                                         | Design                                                                | Spec                                              | Verif                                              |
|--------------------|--------------------------------------------------------------|-----------------------------------------------------------------------|---------------------------------------------------|----------------------------------------------------|
| `apb`              | AMBA APB4 SystemVerilog interface (modports)                | [`design/apb/`](design/apb/)                                          | [`spec/apb/`](spec/apb/)                          | [`verif/apb/`](verif/apb/)                         |
| `ip_cdc_sync`      | Multi-flop level synchronizer                                | [`design/common/ip_cdc_sync.sv`](design/common/ip_cdc_sync.sv)        | [`spec/ip_cdc_sync/`](spec/ip_cdc_sync/)          | [`verif/ip_cdc_sync/`](verif/ip_cdc_sync/)         |
| `ip_cdc_handshake` | 4-phase req/ack vector CDC                                   | [`design/common/ip_cdc_handshake.sv`](design/common/ip_cdc_handshake.sv) | [`spec/ip_cdc_handshake/`](spec/ip_cdc_handshake/) | [`verif/ip_cdc_handshake/`](verif/ip_cdc_handshake/) |
| `ip_async_fifo`    | Gray-code dual-clock async FIFO                              | [`design/common/ip_async_fifo.sv`](design/common/ip_async_fifo.sv)    | [`spec/ip_async_fifo/`](spec/ip_async_fifo/)      | [`verif/ip_async_fifo/`](verif/ip_async_fifo/)     |
| `alu` (sandbox)    | Tiny 8-bit ALU leaf compute (Python golden in `spec/`)       | [`design/sandbox/alu.sv`](design/sandbox/alu.sv)                      | [`spec/sandbox/`](spec/sandbox/)                  | [`verif/sandbox/`](verif/sandbox/), [`verif/sandbox_cocotb/`](verif/sandbox_cocotb/) |
| **`alu_accel`**    | Multi-clock APB-mapped ALU accelerator (composes everything) | [`design/alu_accel/`](design/alu_accel/) (PeakRDL CSR + multi-clock)  | [`spec/alu_accel/`](spec/alu_accel/)              | [`verif/alu_accel/`](verif/alu_accel/)             |

Out-of-box `rb regression -c regression.yaml` passes **12/12** tests
across these blocks; `rb synth-regression -c synth_regression.yaml`
synthesizes the alu leaf (287 gates) and the full system (1265 gates).

## Tooling Scope

`rtl_buddy` adapts to the toolchain your project already uses. In this
template the supported flows are:

- **Verilator** for the open-source compile/sim/regression/coverage path
- **VCS** for teams using Synopsys flows
- **Yosys** (rtl-buddy fork) for synthesis (generic + tech-mapped)
- **cocotb** for Python-driven testbenches
- **Surfer** + WCP for live waveform viewing and headless capture
- **Coverview** for browser-based coverage dashboards
- **PeakRDL** for SystemRDL → SystemVerilog register block generation

## Setup

External prerequisites:

- `uv`, Python 3.11
- A simulator on `PATH` — Verilator (open-source) and/or VCS
- `lcov` for LCOV/HTML coverage export
- `coverview` (Antmicro) for the Coverview package path
- Verible — `brew tap chipsalliance/verible && brew install verible` on macOS (optional, for `rb verible …`)
- Yosys — build the [rtl-buddy fork](https://github.com/rtl-buddy/yosys) onto `PATH` (optional, for `rb synth …`); macOS notes in [`tools/yosys/SETUP_OSX.md`](tools/yosys/SETUP_OSX.md)
- OpenROAD — build from source onto `PATH` (optional, for downstream P&R; macOS notes in [`tools/openroad/SETUP_OSX.md`](tools/openroad/SETUP_OSX.md))
- Surfer — build from the [rtl-buddy fork](https://github.com/rtl-buddy/surfer) onto `PATH` (optional, for `rb wave` and headless waveform capture)

Sync the project environment after cloning:

```bash
uv sync --locked --python 3.11
```

`cocotb`, `pytest`, `info-process` (for the Coverview zip), `peakrdl` +
`peakrdl-regblock` (for CSR generation) and the pinned `rtl_buddy` are
all installed automatically.

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
├── design/
│   ├── apb/                # APB4 SV interface IP
│   ├── common/             # CDC primitives + ip_async_fifo
│   ├── alu_accel/          # system block: PeakRDL CSR, multi-clock top, compute wrapper
│   ├── sandbox/            # tiny ALU leaf DUT
│   └── template/           # starter design files for a new block
├── spec/
│   ├── apb/                ip_cdc_sync/   ip_cdc_handshake/   ip_async_fifo/
│   ├── alu_accel/          # system spec + alu_accel_csr.rdl + alu_accel_model.py
│   ├── sandbox/            # ALU spec + Python golden model
│   └── template/           # starter spec-traceability example
├── verif/
│   ├── apb/   ip_cdc_sync/   ip_cdc_handshake/   ip_async_fifo/   # leaf-IP suites
│   ├── alu_accel/          # system-level multi-clock APB suite
│   ├── sandbox/            # SV/LVM cosim suite + DV report + Surfer layout
│   ├── sandbox_cocotb/     # cocotb cosim against the shared Python golden
│   └── template/           # starter verification files for a new block
├── synth/
│   ├── sandbox/            # Yosys synth of the ALU leaf (generic + Nangate45)
│   └── alu_accel/          # Yosys synth of the system block (generic)
├── common/                 # shared SV verification helpers (LVM macros)
├── tools/                  # toolchain setup notes (yosys, openroad)
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
(cd verif/sandbox && uv run rb test basic)

# Sim regression      — every test listed in regression.yaml (12/12)
uv run rb regression -c regression.yaml

# Coverage regression — same, with merged LCOV HTML and Coverview zip
uv run rb -M cov regression -c regression.yaml \
    --coverage-merge --coverage-html --coverage-coverview

# Waveform viewer     — open Surfer with the suite's signal layout
(cd verif/sandbox && uv run rb wave basic)

# DV report           — replay through Python golden + capture surfer PNGs
(cd verif/sandbox && uv run python build_report.py)

# System-level demo   — multi-clock APB accelerator
(cd verif/alu_accel && uv run rb test csr_smoke)
(cd verif/alu_accel && uv run rb test fifo_stream)

# Regenerate PeakRDL CSRs (from spec/alu_accel/alu_accel_csr.rdl)
(cd design/alu_accel && ./gen_alu_accel_csr.sh)

# Synth regression    — generic synth runs (tech-mapped is gated by reglvl)
uv run rb synth-regression -c synth_regression.yaml
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
  [`spec/sandbox/sandbox_model.py`](spec/sandbox/sandbox_model.py) is
  the Python form of the alu spec, consumed live by the cocotb suite
  and via post-run replay by `verif/sandbox/build_report.py`.
- **Design link**: each `design/<block>/models.yaml` carries
  `spec: "../../spec/<block>/specs.yaml"` so `rb spec check-design`
  verifies every block has a model.
- **Coverage labels**: SV cover-property labels in
  `verif/<block>/cov_*.sv` (and equivalents) match the spec IDs.
- **Test → coverage**: each test in `verif/<block>/tests.yaml`
  declares a `covers:` list of the IDs it targets.

### Try it

```bash
uv run rb spec list             # 6 demonstrator blocks (44 coverage IDs total)
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
(cd verif/sandbox && uv run rb test basic)

# cocotb peer suite — same DUT, Python-driven, scoreboarded against shared golden
(cd verif/sandbox_cocotb && uv run rb test cocotb_random)

# system-level (multi-clock APB)
(cd verif/alu_accel && uv run rb test csr_smoke)

# regression-mode run for speed
(cd verif/sandbox && uv run rb -M reg test random)
```

Per-test artefacts land at `<suite>/artefacts/<test>/` (gitignored).
The SV/LVM sandbox testbench writes a transaction log (`txn.log`)
used later by the DV report.

---

## Regression — `rb regression`

Runs every test listed in a regression config across one or more
suites, with reglvl filtering, summary tables, and machine-readable
output for CI.

### How it is wired

- **Top-level config**: [`regression.yaml`](regression.yaml) lists
  each suite's `tests.yaml` (7 suites today: 4 leaf-IP + sandbox +
  sandbox_cocotb + alu_accel).
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
uv run rb regression -c regression.yaml             # everything (12/12)
uv run rb regression -c regression.yaml -l 0        # only reglvl 0 entries
uv run rb --machine regression -c regression.yaml   # CI-style JSON output
```

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

---

## Golden-Model Cosim — One Spec, Two Flows

The sandbox proves a single Python golden
([`spec/sandbox/sandbox_model.py`](spec/sandbox/sandbox_model.py))
against the same DUT from two independent verif suites. Drift in
either direction surfaces immediately.

### SV/LVM side (`verif/sandbox/`)

- An inline reference function `ref_compute()` in
  [`tb_top.sv`](verif/sandbox/tb_top.sv) mirrors the spec; every cycle
  the registered DUT outputs are compared against it and LVM bumps
  the error count on mismatch.
- Each transaction is also written to `txn.log`. After the run,
  [`build_report.py`](verif/sandbox/build_report.py) replays the log
  through `sandbox_model.py`. Any divergence between SV reference and
  Python golden appears as a "Divergences" block in the per-test
  markdown report.

### cocotb side (`verif/sandbox_cocotb/`)

- Pure cocotb against `toplevel: alu` — no SV testbench wrapper. The
  shared helpers in
  [`_alu_common.py`](verif/sandbox_cocotb/_alu_common.py) import
  `sandbox_model.AluModel` directly and scoreboard live every cycle.
- Two test modules
  ([`test_alu_random.py`](verif/sandbox_cocotb/test_alu_random.py),
   [`test_alu_flags.py`](verif/sandbox_cocotb/test_alu_flags.py)) so
  rtl_buddy test selection maps cleanly to cocotb tests.

### Try it

```bash
(cd verif/sandbox        && uv run rb test random)           # SV cosim
(cd verif/sandbox_cocotb && uv run rb test cocotb_random)    # cocotb cosim
```

Both pass with **zero** mismatches. Break either side (flip a SV
opcode in `ref_compute`, or change a Python op in `sandbox_model.py`)
and the corresponding flow fails loudly.

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
(cd verif/sandbox    && uv run rb test basic)        # produce FST first
(cd verif/sandbox    && uv run rb wave basic)        # open Surfer
(cd verif/alu_accel  && uv run rb wave csr_smoke)    # multi-clock layout
```

---

## DV Report with Waveform Proof

[`verif/sandbox/build_report.py`](verif/sandbox/build_report.py) is a
post-run script (custom rtl_buddy postproc plugins are not yet
supported) that turns each test's artefacts into a markdown DV
report.

### What it produces

For each test in the SV sandbox suite:
- **`report/<test>.md`** — objective, declared `covers:` IDs, replay
  result against the Python golden (transaction count + 0 or N
  divergences), embedded waveform PNG, FST path.
- **`report/<test>.png`** — Surfer headless capture using the shared
  `tb_top.surfer` layout with `export_wave` appended.
- **`report/index.md`** — roll-up table linking every test report.

### How it is wired

- Replays `<suite>/artefacts/<test>/txn.log` through
  `sandbox_model.AluModel.compute()` (same module the cocotb suite
  uses live).
- Appends `export_wave report/<test>.png 1600 600` and `exit` to the
  surfer command file, runs `surfer --headless -c <cmd> dump.fst`.
- Falls back gracefully when surfer isn't on `PATH` — the report
  still lists FST path + divergence summary.

### Try it

```bash
(cd verif/sandbox && uv run rb -M debug regression -c ../../regression.yaml)
(cd verif/sandbox && uv run python build_report.py)
open verif/sandbox/report/index.md
```

---

## PeakRDL Register Generation

The `alu_accel` CSR block is generated from a SystemRDL description
([`spec/alu_accel/alu_accel_csr.rdl`](spec/alu_accel/alu_accel_csr.rdl))
using [PeakRDL-regblock](https://peakrdl-regblock.readthedocs.io/).
The generated SV files are committed; CI runs the regen script and
`git diff --exit-code` to catch drift.

### How it is wired

- **Source of truth**: `spec/alu_accel/alu_accel_csr.rdl` lives with
  the spec, not the design. Edit this when register layout changes.
- **Regen script**:
  [`design/alu_accel/gen_alu_accel_csr.sh`](design/alu_accel/gen_alu_accel_csr.sh)
  invokes `peakrdl regblock` with `--cpuif apb4-flat
  --default-reset rst_n` and patches in Verilator-friendly lint
  waivers on the generated files.
- **Output**: `alu_accel_csr.sv` + `alu_accel_csr_pkg.sv` in
  `design/alu_accel/`. Both are committed.
- **Pinned deps**: `peakrdl` and `peakrdl-regblock` come from the
  rtl-buddy fork via `[tool.uv.sources]` in `pyproject.toml`.
- **Hwif wiring**:
  [`design/alu_accel/alu_accel_top.sv`](design/alu_accel/alu_accel_top.sv)
  consumes the generated `hwif_in`/`hwif_out` structs and threads
  them to the compute domain through `ip_cdc_handshake` /
  `ip_async_fifo`.

### Try it

```bash
# Edit spec/alu_accel/alu_accel_csr.rdl, then:
(cd design/alu_accel && ./gen_alu_accel_csr.sh)

# Regression catches any RTL drift:
uv run rb regression -c regression.yaml
```

---

## Synthesis — `rb synth` / `rb synth-regression`

Tool-agnostic Yosys synthesis with optional technology mapping
against a Liberty file. Same shape as the sim flow: `synth.yaml` per
block, an optional `synth_regression.yaml` discoverable list, and
tool defaults in `root_config.yaml`.

### How it is wired

- **Synthesis config**:
  [`synth/sandbox/synth.yaml`](synth/sandbox/synth.yaml) defines two
  runs:
  - `alu_synth_generic` — tech-independent, `reglvl: 0` (default).
  - `alu_synth_nangate45` — tech-mapped to Nangate45 typical corner,
    `reglvl: 1000` (deferred until the PDK is fetched).
  [`synth/alu_accel/synth.yaml`](synth/alu_accel/synth.yaml) adds the
  whole-system run `alu_accel_synth_generic`.
- **Constraints**:
  [`synth/sandbox/constraints.sdc`](synth/sandbox/constraints.sdc)
  carries a 100 MHz `create_clock`. Yosys extracts the period and
  passes it to ABC for timing-driven mapping; the critical path
  becomes WNS in the results table.
- **Tool defaults**: `cfg-synth-tools` (yosys) and `cfg-synth-libs`
  (`nangate45_typ`) in [`root_config.yaml`](root_config.yaml).
- **PDK download**:
  [`synth/sandbox/download_pdk.sh`](synth/sandbox/download_pdk.sh)
  fetches the Nangate45 Liberty from OpenROAD-flow-scripts (~6 MB).
  `pdk/` is gitignored.
- **Flat-port wrapper for the system**:
  [`design/alu_accel/alu_accel_synth_top.sv`](design/alu_accel/alu_accel_synth_top.sv)
  flattens the APB SV interface so Yosys can elaborate the top.
- **Discoverable regression**:
  [`synth_regression.yaml`](synth_regression.yaml) drives
  `rb synth-regression` across all listed `synth.yaml` files.

### Try it

```bash
# tech-independent — no PDK needed
uv run rb synth alu_synth_generic       -c synth/sandbox/synth.yaml
uv run rb synth alu_accel_synth_generic -c synth/alu_accel/synth.yaml

# tech-mapped — Nangate45 Liberty for the alu leaf
./synth/sandbox/download_pdk.sh
uv run rb synth alu_synth_nangate45 -c synth/sandbox/synth.yaml

# discoverable regression — generic by default; bump -l to include nangate45
uv run rb synth-regression -c synth_regression.yaml
uv run rb synth-regression -c synth_regression.yaml -l 1000
```

The tech-mapped run reports gate count, area (µm²), and worst-negative
slack against the SDC.

---

## The `alu_accel` System Block

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

See [`spec/alu_accel/README.md`](spec/alu_accel/README.md) for the
full register map and behaviour, and
[`verif/alu_accel/testplan.md`](verif/alu_accel/testplan.md) for the
test → coverage mapping.

```bash
(cd verif/alu_accel && uv run rb test csr_smoke)     # CSR-direct
(cd verif/alu_accel && uv run rb test fifo_stream)   # FIFO mode (drives FULL + DRAIN)
uv run rb synth alu_accel_synth_generic -c synth/alu_accel/synth.yaml
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
- Rewrite the repo docs ([`README.md`](README.md),
  [`AGENTS.md`](AGENTS.md)) so they describe your project instead of
  the template.

An AI agent can also follow the instructions in
[`AGENTS.md`](AGENTS.md) to help adapt this template into your
project.
