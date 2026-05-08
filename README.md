# RTL-Buddy Project Template

Starter RTL project to use [`rtl_buddy`](https://github.com/rtl-buddy/rtl_buddy).
A clean starting point for a new project that ships a runnable, end-to-end
demonstrator covering every headline `rtl_buddy` capability — spec, test,
regression, coverage, golden-model cosim (SV + cocotb), waveforms, DV
reports, and synthesis — all driven from a tiny 8-bit ALU sandbox so the
mechanics stay in focus instead of the DUT.

## Tooling Scope

`rtl_buddy` adapts to the toolchain your project already uses. In this
template the primary supported flows are:

- **Verilator** for the open-source compile/sim/regression/coverage path
- **VCS** for teams using Synopsys flows
- **Yosys** (rtl-buddy fork) for synthesis
- **cocotb** for Python-driven testbenches
- **Surfer** + WCP for live waveform viewing and headless capture
- **Coverview** for browser-based coverage dashboards

## Setup

External prerequisites:

- `uv`, Python 3.11
- A simulator on `PATH` — Verilator (open-source) and/or VCS
- `lcov` for LCOV/HTML coverage export
- `coverview` (Antmicro) for the Coverview package path
- Verible — `brew tap chipsalliance/verible && brew install verible` on macOS (optional, for `rb verible ...`)
- Yosys — build the [rtl-buddy fork](https://github.com/rtl-buddy/yosys) onto `PATH` (optional, for `rb synth ...`)
- Surfer — build from the [rtl-buddy fork](https://github.com/rtl-buddy/surfer) onto `PATH` (optional, for `rb wave` and headless waveform capture)

Sync the project environment after cloning:

```bash
uv sync --locked --python 3.11
```

`cocotb`, `pytest`, `info-process` (for Coverview zip) and the pinned
`rtl_buddy` are installed automatically.

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
├── root_config.yaml        # project-wide builder, platform, Verible, synth, surfer, coverage config
├── regression.yaml         # top-level sim regression list
├── synth_regression.yaml   # top-level synth regression list
├── design/
│   ├── sandbox/            # tiny ALU DUT (the demonstrator)
│   ├── cocotb_ex/          # standalone cocotb demo RTL
│   └── template/           # starter design files for a new block
├── spec/
│   ├── sandbox/            # ALU spec + Python golden model (shared by both verif suites)
│   └── template/           # starter spec-traceability example
├── verif/
│   ├── sandbox/            # SV/LVM cosim suite + DV report + Surfer layout
│   ├── sandbox_cocotb/     # cocotb cosim against the shared Python golden
│   ├── cocotb_ex/          # standalone cocotb demo suite
│   └── template/           # starter verification files for a new block
├── synth/
│   └── sandbox/            # Yosys synth (generic + Nangate45 tech-mapped)
├── common/                 # shared RTL helpers (LVM macros etc.)
├── tools/                  # vendored project tooling (placeholder)
└── pyproject.toml          # uv-managed project env + pinned rtl_buddy
```

## Quick Start

The sandbox demonstrator runs out-of-box with Verilator. From the repo
root, after `uv sync`:

```bash
# Spec traceability   — list spec blocks + close spec→design→coverage loop
uv run rb spec list
uv run rb spec check-design
uv run rb spec check-coverage

# Single test         — one named test in a suite (default: debug builder mode)
(cd verif/sandbox && uv run rb test basic)

# Sim regression      — every test listed in regression.yaml
uv run rb regression -c regression.yaml

# Coverage regression — same, with merged LCOV HTML and Coverview zip
uv run rb -M cov regression -c regression.yaml \
    --coverage-merge --coverage-html --coverage-coverview

# Waveform viewer     — open Surfer with the suite's signal layout
(cd verif/sandbox && uv run rb wave basic)

# DV report           — replay through Python golden + capture surfer PNGs
(cd verif/sandbox && uv run python build_report.py)
open verif/sandbox/report/index.md

# Synth               — Yosys synthesis (generic + tech-mapped)
uv run rb synth-regression -c synth_regression.yaml
```

Each section below walks through *what* the feature does, *how it is
wired*, and where to look in the sandbox for a working example.

---

## Spec Traceability — `rb spec`

`rb spec` formalises the link from human-readable spec → executable
golden model → SV functional coverage → test plan. Drift in any
direction shows up as a missing item rather than going unnoticed.

### How it is wired

- **Block definition**: [`spec/sandbox/specs.yaml`](spec/sandbox/specs.yaml)
  declares the block name, prose docs, and a list of `coverage-items`
  with stable IDs (e.g. `SAND-FUNC-OP-ADD`).
- **Prose spec**: [`spec/sandbox/README.md`](spec/sandbox/README.md) is
  the human-readable specification — interface, behaviour, edge cases.
  It is the source of truth that the rest follows.
- **Executable golden model**: [`spec/sandbox/sandbox_model.py`](spec/sandbox/sandbox_model.py)
  encodes the spec in Python. Both verif suites consume it directly.
- **Design link**: [`design/sandbox/models.yaml`](design/sandbox/models.yaml)
  carries `spec: "../../spec/sandbox/specs.yaml"` so `rb spec
  check-design` can verify each block has a model.
- **Coverage labels**: [`verif/sandbox/cov_alu.sv`](verif/sandbox/cov_alu.sv)
  uses cover-property labels whose names match the `SAND-FUNC-*` IDs in
  `specs.yaml` so the loop closes.
- **Test → coverage**: each test in [`verif/sandbox/tests.yaml`](verif/sandbox/tests.yaml)
  declares a `covers:` list of the coverage IDs it targets.

### Try it

```bash
uv run rb spec list             # blocks + coverage-item counts
uv run rb spec check-design     # every block points at a design model
uv run rb spec check-coverage   # every coverage ID is referenced by a test
```

A failing `check-coverage` row means an ID exists in `specs.yaml` but no
test references it — typically a missing entry in `tests.yaml: covers:`,
or a label drift between spec and `cov_alu.sv`.

---

## Tests — `rb test`

A single test runs the compile + sim of one named entry from a
suite-local `tests.yaml`. Use this for local debug, before promoting
work to a regression.

### How it is wired

- **Suite layout**: a verif suite is a directory containing `tests.yaml`
  plus any SV testbenches / cocotb modules. The sandbox has two:
  [`verif/sandbox/`](verif/sandbox/) (SV/LVM) and
  [`verif/sandbox_cocotb/`](verif/sandbox_cocotb/) (pure cocotb).
- **`tests.yaml`** declares two top-level lists:
  - `testbenches:` — name, filelist, optional `toplevel:` and `cocotb:`
    block (for cocotb-driven flows)
  - `tests:` — per-test `name`, `desc`, `reglvl`, `plusargs`,
    `plusdefines`, `model:` + `model_path:`, `testbench:`, `covers:`
- **Models**: [`design/sandbox/models.yaml`](design/sandbox/models.yaml)
  maps each model name to a filelist (`-F file.f` allowed). The
  testbench wraps that with its own files.
- **Builder modes**: `-M debug` (default) compiles with FST trace and
  full assertions. `-M reg` strips trace for speed. `-M cov` adds
  Verilator coverage. Modes are defined in
  [`root_config.yaml`](root_config.yaml).

### Try it

```bash
# SV/LVM, single test
(cd verif/sandbox && uv run rb test basic)

# cocotb peer suite — same DUT, Python-driven, scoreboarded against the same golden
(cd verif/sandbox_cocotb && uv run rb test cocotb_random)

# regression-mode run for speed
(cd verif/sandbox && uv run rb -M reg test random)
```

Per-test artefacts land at `<suite>/artefacts/<test>/` (gitignored). The
SV/LVM testbench writes a transaction log (`txn.log`) used later by the
DV report.

---

## Regression — `rb regression`

Runs every test listed in a regression config across one or more suites,
with reglvl filtering, summary tables, and machine-readable output for
CI.

### How it is wired

- **Top-level config**: [`regression.yaml`](regression.yaml) lists each
  suite's `tests.yaml`. The sandbox regression includes the SV/LVM
  suite, the cocotb peer, and the standalone cocotb example.
- **Reglvl gating**: each test in `tests.yaml` has a `reglvl` (0 = always
  run, larger numbers = deferred tiers, 10000 = disabled). `--reg-level
  N` (alias `-l`) caps the run.
- **Pointer in `root_config.yaml`**: `cfg-rtl-reg.reg-cfg-path` is the
  default config path so `rb regression` (no `-c`) just works from the
  repo root.
- **Machine mode**: `--machine` switches the renderer to JSON Lines for
  CI (used by `.github/workflows/verilator.yml`).

### Try it

```bash
# everything
uv run rb regression -c regression.yaml

# only reglvl 0 entries
uv run rb regression -c regression.yaml -l 0

# CI-style JSON output
uv run rb --machine regression -c regression.yaml
```

Out-of-box this passes 7/7 (4 SV sandbox + 2 cocotb sandbox + 1 cocotb_ex).

---

## Coverage + Coverview — `rb -M cov regression …`

Verilator coverage collection, merge, LCOV HTML export, and packaging
into a Coverview zip for the browser dashboard.

### How it is wired

- **Builder mode**: `-M cov` selects the `cov` block in `cfg-rtl-builder`
  (extra `--coverage-line/-toggle/-expr/-user` flags).
- **Per-test merge**: `--coverage-merge` collects coverage across the
  whole regression into `<suite>/cov_dir/coverage_merged.{dat,info}`.
- **HTML export**: `--coverage-html` runs LCOV → `coverage_merge.html`.
- **Coverview zip**: `--coverage-coverview` uses the `info-process`
  package (declared in `pyproject.toml`) to package the merged data into
  `<suite>/coverview_regression.zip` per [`coverview.md`](coverview.md).
- **Coverview config**: `cfg-coverview` in `root_config.yaml` controls
  the dashboard title and table type.
- **Loop with spec**: `tests.yaml` `covers:` IDs are listed in the
  generated DV report and validated by `rb spec check-coverage`.

### Try it

```bash
uv run rb -M cov regression -c regression.yaml \
    --coverage-merge --coverage-html --coverage-coverview
open verif/sandbox/coverage_merge.html
# Coverview viewer setup: see coverview.md
```

---

## Golden-Model Cosim — One Spec, Two Flows

The sandbox proves a single Python golden ([`spec/sandbox/sandbox_model.py`](spec/sandbox/sandbox_model.py))
against the same DUT from two independent verif suites. Drift in either
direction surfaces immediately.

### SV/LVM side (`verif/sandbox/`)

- An inline reference function `ref_compute()` in [`tb_top.sv`](verif/sandbox/tb_top.sv)
  mirrors the spec; every cycle the registered DUT outputs are compared
  against it and LVM bumps the error count on mismatch.
- Each transaction is also written to `txn.log` (cycle, op, a, b, y,
  flags). After the run, [`build_report.py`](verif/sandbox/build_report.py)
  replays the log through `sandbox_model.py`. Any divergence between SV
  reference and Python golden is reported as a "Divergences" block in
  the per-test markdown.

### cocotb side (`verif/sandbox_cocotb/`)

- Pure cocotb against `toplevel: alu` — no SV testbench wrapper. The
  shared common helpers in [`_alu_common.py`](verif/sandbox_cocotb/_alu_common.py)
  import `sandbox_model.AluModel` directly and scoreboard live, every
  cycle.
- Two test modules ([`test_alu_random.py`](verif/sandbox_cocotb/test_alu_random.py),
  [`test_alu_flags.py`](verif/sandbox_cocotb/test_alu_flags.py)) so
  rtl_buddy test selection maps cleanly to cocotb tests.

### Try it

```bash
# SV cosim — internal scoreboard
(cd verif/sandbox && uv run rb test random)

# cocotb cosim — live Python-golden scoreboard
(cd verif/sandbox_cocotb && uv run rb test cocotb_random)
```

Both pass with **zero** mismatches. Break either side (e.g. flip a SV
opcode in `ref_compute`, or change a Python op in `sandbox_model.py`)
and the corresponding flow will fail loudly.

---

## Surfer Waveforms — `rb wave`

`rb wave` opens the [Surfer](https://surfer-project.org/) waveform
viewer for a test's FST and connects it to your editor via WCP, so
right-clicking a signal jumps to its declaration with inline value
annotation at the cursor timestamp.

### How it is wired

- **Tool config**: `cfg-surfer` in [`root_config.yaml`](root_config.yaml)
  declares the surfer binary path (`"surfer"` resolves via `$PATH`).
- **Per-suite layout**: [`verif/sandbox/tb_top.surfer`](verif/sandbox/tb_top.surfer)
  is a Surfer command file (groups, dividers, signal list, zoom_fit).
  `rb wave <test>` autoloads `<test>.surfer` if present, else
  `tb_top.surfer`.
- **Headless capture**: the same command file is also used by the DV
  report builder to render PNGs in `--headless --exit-after-commands`
  mode.

### Try it

```bash
# Generate a debug-mode FST first if not already there
(cd verif/sandbox && uv run rb test basic)
(cd verif/sandbox && uv run rb wave basic)
```

---

## DV Report with Waveform Proof

`verif/sandbox/build_report.py` is a post-run script (custom rtl_buddy
postproc plugins are not yet supported) that turns each test's
artefacts into a markdown DV report.

### What it produces

For each test in the SV suite:
- **`report/<test>.md`** — objective, declared `covers:` IDs, replay
  result against the Python golden (transaction count + 0 or N
  divergences), embedded waveform PNG, FST path.
- **`report/<test>.png`** — Surfer headless capture of the run using the
  shared `tb_top.surfer` layout (`export_wave` command at the end).
- **`report/index.md`** — roll-up table linking every test report.

### How it is wired

- Replays `<suite>/artefacts/<test>/txn.log` through
  `sandbox_model.AluModel.compute()` (same module the cocotb suite uses
  live).
- For each test it appends `export_wave report/<test>.png 1600 600
  exit` to the surfer command file and runs
  `surfer --headless -c <cmd> dump.fst`.
- Falls back gracefully when surfer isn't on `PATH` — the report still
  lists the FST path and divergence summary.

### Try it

```bash
(cd verif/sandbox && uv run rb -M debug regression -c ../../regression.yaml)
(cd verif/sandbox && uv run python build_report.py)
open verif/sandbox/report/index.md
```

---

## Synthesis — `rb synth` / `rb synth-regression`

Tool-agnostic Yosys synthesis with optional technology mapping against
a Liberty file. Same shape as the sim flow: `synth.yaml` per block, an
optional `synth_regression.yaml` discoverable list, and tool defaults
in `root_config.yaml`.

### How it is wired

- **Synthesis config**: [`synth/sandbox/synth.yaml`](synth/sandbox/synth.yaml)
  defines two runs:
  - `alu_synth_generic` — tech-independent, `reglvl: 0` (default
    regression).
  - `alu_synth_nangate45` — tech-mapped to Nangate45 typical corner,
    `reglvl: 1000` (deferred until the PDK is fetched).
- **Constraints**: [`synth/sandbox/constraints.sdc`](synth/sandbox/constraints.sdc)
  carries a 100 MHz `create_clock`. The Yosys backend extracts the
  period and passes it to ABC for timing-driven mapping; the critical
  path becomes WNS in the results table.
- **Tool defaults**: `cfg-synth-tools` (yosys) and `cfg-synth-libs`
  (`nangate45_typ`) in [`root_config.yaml`](root_config.yaml).
- **PDK download**: [`synth/sandbox/download_pdk.sh`](synth/sandbox/download_pdk.sh)
  fetches the Nangate45 Liberty from OpenROAD-flow-scripts (~6 MB).
  `pdk/` is gitignored.
- **Discoverable regression**: [`synth_regression.yaml`](synth_regression.yaml)
  drives `rb synth-regression` across all listed `synth.yaml` files.

### Try it

```bash
# tech-independent — no PDK needed
uv run rb synth alu_synth_generic -c synth/sandbox/synth.yaml

# tech-mapped — Nangate45
./synth/sandbox/download_pdk.sh
uv run rb synth alu_synth_nangate45 -c synth/sandbox/synth.yaml

# discoverable regression — generic by default; bump -l to include nangate45
uv run rb synth-regression -c synth_regression.yaml
uv run rb synth-regression -c synth_regression.yaml -l 1000
```

The tech-mapped run reports gate count, area (µm²), and worst-negative
slack against the SDC.

---

## Building Your Own Project From This Template

Typical next steps:

- Add real blocks alongside `sandbox/` (or replace it once you've
  internalised the patterns).
- Use [`spec/template/`](spec/template/), [`design/template/`](design/template/),
  and [`verif/template/`](verif/template/) as boilerplate copies for a
  new block.
- Update [`root_config.yaml`](root_config.yaml) with your preferred
  builders, flags, and tool entries.
- Expand [`regression.yaml`](regression.yaml) and
  [`synth_regression.yaml`](synth_regression.yaml) to include your real
  suites.
- Rewrite the repo docs ([`README.md`](README.md), [`AGENTS.md`](AGENTS.md))
  so they describe your project instead of the template.

An AI agent can also follow the instructions in [`AGENTS.md`](AGENTS.md)
to help adapt this template into your project.
