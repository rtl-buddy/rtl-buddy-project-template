# RTL-Buddy Project Template

Starter RTL project to use `rtl_buddy`.

This repository is a clean starting point for a new RTL project: it includes a runnable example design, example verification content, all with `rtl_buddy` infrastructure. Use this template to try out `rtl_buddy`, or as the boilerplate for a new project.

## What This Template Includes

- A pinned `rtl_buddy` dependency managed with `uv`
- A working example design under [`design/sandbox/`](design/sandbox/)
- A matching verification suite under [`verif/sandbox/`](verif/sandbox/)
- Starter blocks and configs that demonstrate `rtl_buddy` features under [`design/template/`](design/template/) and [`verif/template/`](verif/template/)
- A minimal Verilator coverage example, including merged HTML coverage export

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

This writes `SKILL.md` to `~/.claude/skills/rtl_buddy/` and `~/.codex/skills/rtl_buddy/`. Re-run after updating `rtl_buddy` to refresh the content. See `uv run rb skill --help` for project-scoped install and other options.

## Repository Layout

```text
.
├── root_config.yaml        # project-wide builder, platform, Verible, and regression config
├── design/
│   ├── regression.yaml     # top-level regression list
│   ├── sandbox/            # runnable example block
│   └── template/           # starter design files for a new block
├── verif/
│   ├── sandbox/            # runnable example test suite
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

Generate a filelist from the sandbox model definition:

```bash
uv run rb filelist test_module -c design/sandbox/models.yaml
```

If you have Verible installed and want to exercise the Verible integration:

```bash
uv run rb verible syntax design/sandbox/test_module.sv
```

## Coverage Example

The template block includes a minimal Verilator coverage setup so you can try the full coverage path without adding your own design first.

```bash
cd verif/template
uv run rb --builder-mode cov test basic -c tests.yaml --coverage-merge --coverage-html
```

This uses the `cov` builder mode from [`root_config.yaml`](root_config.yaml) with the starter files in [`design/template/`](design/template/) and [`verif/template/`](verif/template/). Merged coverage artifacts are written in the suite directory.

`lcov` and Antmicro `coverview` are external system-level dependencies for the HTML and Coverview export paths.

## Building Your Own Project From This Template

Typical next steps:

- Add blocks
- Use [`design/template/`](design/template/) and [`verif/template/`](verif/template/) as references for rtl_buddy usage
- Update [`root_config.yaml`](root_config.yaml) with your preferred builders, flags, and project defaults
- Expand [`design/regression.yaml`](design/regression.yaml) to include your real suites
- Rewrite the repo docs so they describe your project instead of the template

An AI agent can also follow instructions in [`AGENTS.md`](AGENTS.md) to help adapt this template into your real project.
