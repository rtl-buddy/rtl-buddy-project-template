# RTL-Buddy Project Template

Starter RTL project to use `rtl_buddy`.

This repository is a clean starting point for a new RTL project: it includes a runnable example design, example verification content, all with `rtl_buddy` infrastructure. Use this template to try out `rtl_buddy`, or as the boilerplate for a new project.

## What This Template Includes

- A pinned `rtl_buddy` dependency managed with `uv`
- **Sandbox demonstrator** — a tiny ALU with end-to-end coverage of `rtl_buddy`'s headline features (see "Sandbox Demonstrator" below)
- A first-class cocotb/Verilator example under [`verif/cocotb_ex/`](verif/cocotb_ex/)
- Starter blocks and configs under [`design/template/`](design/template/) / [`verif/template/`](verif/template/) / [`spec/template/`](spec/template/)
- Verilator coverage with merged LCOV HTML and Coverview package export
- Surfer integration via `rb wave` and headless waveform capture in DV reports

## Sandbox Demonstrator

The sandbox is a tiny 8-bit ALU intentionally chosen as the smallest DUT
that can show every major `rtl_buddy` capability without overshadowing
the framework. **One DUT, one spec, two cosim flows:**

| Capability                             | Where                                                         |
|----------------------------------------|---------------------------------------------------------------|
| Spec authoring (prose + IDs)           | [`spec/sandbox/README.md`](spec/sandbox/README.md), [`specs.yaml`](spec/sandbox/specs.yaml) |
| Spec → functional coverage             | [`verif/sandbox/cov_alu.sv`](verif/sandbox/cov_alu.sv) (cover labels match `SAND-FUNC-*` IDs) |
| Test planning (`covers:` mapping)      | [`verif/sandbox/testplan.md`](verif/sandbox/testplan.md), [`tests.yaml`](verif/sandbox/tests.yaml) |
| Coverage collection + Coverview        | `rb -M cov regression --coverage-merge --coverage-html --coverage-coverview` |
| Golden-model cosim (SV side)           | inline reference in [`verif/sandbox/tb_top.sv`](verif/sandbox/tb_top.sv) + post-run replay through [`spec/sandbox/sandbox_model.py`](spec/sandbox/sandbox_model.py) |
| Golden-model cosim (cocotb side)       | [`verif/sandbox_cocotb/`](verif/sandbox_cocotb/) drives the **same DUT** against the **same Python golden** live |
| Surfer integration (`rb wave`)         | [`verif/sandbox/tb_top.surfer`](verif/sandbox/tb_top.surfer) — auto-loaded by `rb wave <test>` |
| DV report w/ waveform proof            | [`verif/sandbox/build_report.py`](verif/sandbox/build_report.py) — emits `report/<test>.md` with headless surfer captures |

```bash
uv run rb regression -c regression.yaml                              # run all suites
uv run rb -M cov regression -c regression.yaml \
    --coverage-merge --coverage-html --coverage-coverview            # + coverage
uv run rb spec check-coverage                                        # close spec → cov loop
uv run rb wave basic                                                 # live Surfer
(cd verif/sandbox && uv run python build_report.py)                  # DV report
open verif/sandbox/report/index.md
```

## Tooling Scope

`rtl_buddy` can be adapted to different project toolchains. In this template, the primary supported flows are:

- Verilator for the open-source compile, simulation, regression, and coverage path
- VCS for teams using Synopsys simulation flows

## Setup

Install the external prerequisites first:

- `uv`
- Python 3.11
- A simulator on `PATH`:
  - Verilator for the primary open-source flow
  - VCS if your environment uses Synopsys flows
- `cocotb` is installed by the project environment for the included Python-driven example
- `lcov` at the system level for LCOV/HTML coverage export
- Antmicro `coverview` at the system level for Coverview package generation
- Verible — `brew tap chipsalliance/verible && brew install verible` on macOS (optional, only needed for `rb verible ...` commands)

Then sync the project environment after cloning:

```bash
uv sync --locked --python 3.11
```

This installs the pinned `rtl_buddy` dependency and the Python packages used by the template.

Verible must be installed separately (see prerequisites above) before using `rb verible ...` commands.

Preferred command style:

```bash
uv run rb regression
```

If you are starting fresh with the open-source path, use Verilator first. It is the easiest way to validate that the project layout, testbench wiring, and `rtl_buddy` setup are all working.

`rtl_buddy` ships an agent skill for Claude Code and Codex. Install it once per machine so AI-assisted workflows can use it:

```bash
uv run rb skill install
```

If you want the skill files to live inside this repo instead, install the project-scoped copy:

```bash
uv run rb skill install --project
```

That writes `.claude/skills/rtl_buddy/` and `.agents/skills/rtl_buddy/` under the project root. Both directories are gitignored in the template, so they are safe to use in template-derived repos. Re-run after updating `rtl_buddy` to refresh the content. See `uv run rb skill --help` for scope details and other options.

## Repository Layout

```text
.
├── root_config.yaml        # project-wide builder, platform, Verible, and regression config
├── regression.yaml         # top-level regression list
├── design/
│   ├── cocotb_ex/          # cocotb demo RTL
│   ├── sandbox/            # tiny ALU DUT (sandbox demonstrator)
│   └── template/           # starter design files for a new block
├── spec/
│   ├── sandbox/            # ALU spec + Python golden model (shared by both verif suites)
│   └── template/           # starter spec traceability example
├── verif/
│   ├── cocotb_ex/          # cocotb demo suite
│   ├── sandbox/            # SV/LVM cosim + DV report + Surfer layout
│   ├── sandbox_cocotb/     # cocotb cosim against the shared Python golden
│   └── template/           # starter verification files for a new block
├── common/                 # shared RTL helpers used by the examples
├── tools/                  # Bundling tools in your project
└── pyproject.toml          # project env and pinned rtl_buddy dependency
```

## Quick Start

Run the example unit test from the suite directory:

```bash
cd verif/sandbox
uv run rb test basic
```

Run the example regression from the repo root:

```bash
cd ../..
uv run rb regression
```

Run the cocotb example from its suite directory:

```bash
cd verif/cocotb_ex
uv run rb test basic
```

Generate a filelist from the sandbox model definition:

```bash
uv run rb filelist alu -c design/sandbox/models.yaml
```

If you have Verible installed and want to exercise the Verible integration:

```bash
uv run rb verible syntax design/sandbox/alu.sv
```

## Coverage Example

The template block includes a minimal Verilator coverage setup so you can try the full coverage path without adding your own design first.

```bash
cd verif/template
uv run rb --builder-mode cov test basic -c tests.yaml --coverage-merge --coverage-html
```

This uses the `cov` builder mode from [`root_config.yaml`](root_config.yaml) with the starter files in [`design/template/`](design/template/) and [`verif/template/`](verif/template/). Merged coverage artifacts are written in the suite directory.

`lcov` and Antmicro `coverview` are external system-level dependencies for the HTML and Coverview export paths.

## Spec Traceability Example

The starter block also demonstrates the optional `rb spec` workflow described in the main `rtl_buddy` docs.

```bash
uv run rb spec list
uv run rb spec check-design
uv run rb spec check-coverage
```

This uses [`spec/template/specs.yaml`](spec/template/specs.yaml), the `spec:` pointer in [`design/template/models.yaml`](design/template/models.yaml), and the `covers:` annotations in [`verif/template/tests.yaml`](verif/template/tests.yaml).

## Building Your Own Project From This Template

Typical next steps:

- Add blocks
- Use [`spec/template/`](spec/template/), [`design/template/`](design/template/), and [`verif/template/`](verif/template/) as references for rtl_buddy usage
- Update [`root_config.yaml`](root_config.yaml) with your preferred builders, flags, and project defaults
- Expand [`regression.yaml`](regression.yaml) to include your real suites
- Rewrite the repo docs so they describe your project instead of the template

An AI agent can also follow instructions in [`AGENTS.md`](AGENTS.md) to help adapt this template into your real project.
