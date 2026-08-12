# AGENTS.md - rtl-buddy-proj-template

## Role

This repo is both:

- a starter RTL project template for `rtl_buddy`
- a runnable reference project that demonstrates the expected repo layout

The project should stay runnable. `design/demo_tiny_alu/` is the primary small working example and should not be left broken. Larger demos may require optional external tools, but their configs and docs should stay internally consistent.

## Block Categories

Blocks shipped with this template fall into four categories. Preserve this categorisation in new work: name reusable leaf IP without a prefix, keep starter skeletons under `template/`, name integrated demos with `demo_*`, and keep third-party vendor examples explicit.

- **Base IP** — leaf, reusable components (`apb`, `ip_cdc_sync`,
  `ip_cdc_handshake`, `ip_async_fifo`). No prefix.
- **Workflow templates** — `template/` skeletons that show the
  expected spec/design/verif/test shape for a new block. Copy these
  when starting fresh.
- **Demo blocks** — `demo_*` end-to-end examples that exercise
  specific rtl_buddy capabilities (`demo_tiny_alu`,
  `demo_tiny_alu_cocotb`, `demo_tiny_alu_sc`,
  `demo_tiny_alu_subsys`, `demo_cdc_src_sync`, the grouped
  `demo_abv` family, `demo_axi_2x2`, and `demo_pulp_platform_axi`).
  Safe to delete when starting a new project.

Preserve this categorisation in new work — name new leaf IP without a
prefix, new demos with `demo_*`, and don't touch `template/` unless
you're updating the starter skeleton itself. The ABV/formal demos are a
special grouped family: their design models live under `design/demo_abv/`,
while their run configs live under `fpv/demo_abv/<block>/` and, where
applicable, `verif/demo_abv/<block>/`.

## This Is A Template Repo

This is a GitHub template repo. New projects are created from it via the "Use this template" button on GitHub, not by forking. It contains template structure, example designs, and `rtl_buddy` integration that downstream projects inherit.

### When Creating A New Project From This Template

Rewrite the following files so they describe the new project, not this template:

- **`README.md`** - replace template descriptions with the new project's name, purpose, and team-specific notes.
- **`CLAUDE.md` / `AGENTS.md`** - keep the `rtl_buddy` workflow guidance, but rewrite role and layout sections for the new project.

Remove or update anything that refers to:

- example project names or block names that no longer apply
- private infrastructure, private links, or organization-specific paths
- vendoring or dependency arrangements that the new project does not use
- optional tool flows that the new project will not support

The `rtl_buddy` workflow sections below are worth keeping in downstream projects because they describe how to use the toolchain inside a project repo.

## Important Paths

```text
root_config.yaml                         # builders, platforms, tools, defaults
regression.yaml                          # top-level sim regression list
synth_regression.yaml                    # top-level synth regression list
fpv_regression.yaml                      # top-level formal regression list
fpga_regression.yaml                     # top-level FPGA implementation regression list
design/template/                         # starter RTL skeleton
spec/template/                           # starter spec traceability skeleton
verif/template/                          # starter verification skeleton
design/demo_tiny_alu/                    # primary leaf demo design
verif/demo_tiny_alu*/                    # SV, cocotb, and SystemC peer suites
verif/icarus_smoke/                      # minimal Icarus builder-selection example
lint/cdc/cdc.yaml                        # CDC analyses, including slang and blackbox examples
fpga/demo_cdc_open/                      # openXC7 FPGA flow example
fpv/demo_abv/                            # FPV and ABV examples
pyproject.toml                           # uv-managed project environment and rtl_buddy dependency pin
uv.lock                                  # committed lockfile for reproducible project setup
.python-version                          # pinned Python version for uv
```

The `rtl_buddy` agent skill is bundled inside the `rtl_buddy` wheel and materialized on demand with `uv run rb skill install`. Default scope is user-level (`~/.claude/skills/rtl_buddy/`, `~/.codex/skills/rtl_buddy/`); `--project` installs into `.claude/skills/rtl_buddy/` and `.agents/skills/rtl_buddy/` under the project root instead. Both project-level dirs are gitignored.

## Fresh Clone Setup

### Prerequisites (install externally)

Required for the base sanity path:

- **uv** - install from Astral and make sure it is on `PATH`.
- **Python 3.11** - standard interpreter for this repo; `.python-version` pins it for uv.
- **Verilator** - e.g. `brew install verilator` on macOS, or build from source.
- **Verible** - e.g. `brew tap chipsalliance/verible && brew install verible` on macOS, or see the Verible releases for other platforms.

Feature-dependent tools include VCS, SystemC, Yosys, yosys-slang, OpenROAD, KLayout, Surfer, Coverview, PeakRDL, SymbiYosys plus a solver, `rtl-buddy-cdc`, `rtl-buddy-xeno`, and `rtl-buddy-axi-profiler`. The README gives the current install notes and which demo uses each tool.

If you plan to use `demo_pulp_platform_axi`, initialise the vendor submodules after cloning:

```bash
git submodule update --init --recursive
```

### Setup steps

```bash
uv sync --locked --python 3.11
```

This installs the locked project environment. Run it once after cloning and again whenever `pyproject.toml` or `uv.lock` changes.

Install the `rtl_buddy` agent skill once per machine so AI-assisted workflows can use it:

```bash
uv run rb skill install
```

Re-run after upgrading `rtl_buddy`. Use `--project` to install into this repo instead of your user home; `uv run rb skill --help` shows all options.

Optionally, wire up the Neovim editor integration - one command installs the unified [`rtl-buddy-nvim`](https://github.com/rtl-buddy/rtl-buddy-nvim) plugin (hub auto-connect plus `rb wave` inline signal-value annotations), with no manual plugin clone or `init.lua` edits:

```bash
uv run rb nvim-install
```

Re-run with `--update` after upgrading `rtl_buddy`. See the [wave / nvim docs](https://rtl-buddy.github.io/rtl_buddy/latest/concepts/wave/#nvim-setup).

## rtl_buddy Development Overrides

Normal project work should stay on the pinned dependencies in `pyproject.toml` / `uv.lock`.

For validating unreleased `rtl_buddy` and/or `rtl-buddy-cdc` changes against this project, a standing branch exists:

- **`dev/local-rtl-buddy`** - identical to `main` except for editable `[tool.uv.sources]` overrides in `pyproject.toml` that point the toolchain at sibling local checkouts:

  ```toml
  rtl_buddy     = { path = "../../../rtl_buddy",     editable = true }
  rtl-buddy-cdc = { path = "../../../rtl-buddy-cdc", editable = true }
  ```

  The `rtl_buddy` version pin is relaxed so the editable checkout (a dynamic dev version) satisfies it. Check the branch out in a worktree (e.g. `.worktrees/dev-local/`) and test against whichever branches are checked out in the sibling `rtl_buddy/` and `rtl-buddy-cdc/` repos. Keep only the override(s) you actually need - if you're testing just `rtl_buddy`, drop the `rtl-buddy-cdc` line (and vice versa) and re-run `uv lock`. Not meant to be merged.

This branch is the standard place to validate `rtl_buddy` / `rtl-buddy-cdc` feature branches end-to-end before publishing a release. Keep `main` on the pinned PyPI/git dependencies so day-to-day clones stay reproducible.

## Validation Commands

Use this repo to validate the project setup and `rtl_buddy` integration. Prefer `--machine` when an agent will parse the result.

```bash
# from repo root
uv run rb --machine regression -c regression.yaml
uv run rb --machine regression -c regression.yaml -l 1000
uv run rb --machine cdc-regression -c lint/cdc/cdc_regression.yaml
uv run rb --machine fpv-regression -c fpv_regression.yaml
uv run rb --machine fpga-regression -c fpga_regression.yaml -l 1000
uv run rb --machine synth-regression -c synth_regression.yaml
uv run rb --machine filelist demo_tiny_alu -c design/demo_tiny_alu/models.yaml
uv run rb --machine verible syntax design/demo_tiny_alu/demo_tiny_alu.sv
uv run rb --machine spec list
uv run rb --machine spec check-design
uv run rb --machine spec check-coverage

# from suite dir
cd verif/demo_tiny_alu
uv run rb --machine test basic

cd ../icarus_smoke
uv run rb --machine test basic
uv run rb --machine --builder verilator test basic

# Hierarchy rendering (rtl-buddy-view #99). `--view dut` (default)
# renders the model's module tree rooted at its DUT; `--view tb`
# renders the testbench tree with the DUT called out as a subtree,
# using the test's tb.toplevel to anchor the new --tb-top flag.
uv run rb --machine hier demo_tiny_alu                   --format tree   # DUT view
uv run rb --machine hier basic --view tb --format tree                   # TB view

cd ../demo_tiny_alu_cocotb
uv run rb --machine test cocotb_random

cd ../demo_tiny_alu_sc       # requires $SYSTEMC_HOME or cfg-systemc.home set
uv run rb --machine test basic_sc

cd ../demo_axi_2x2
uv run rb --machine test basic_traffic
uv run rb --machine axi-profile run basic

# from an FPV suite dir
cd fpv/demo_abv/demo_abv_basic
uv run rb --machine fpv          # runs every verification in fpv.yaml
uv run rb --machine fpv --list   # dry-list verification names
```

`test` and `randtest` are typically run from the suite directory so relative testbench paths resolve correctly. Likewise, run `fpv` from the suite directory that contains the relevant `fpv.yaml`, and run `fpv-regression` from the repo root.

`hier --view tb` requires the test's testbench entry in `tests.yaml` to carry a `toplevel:` field (the SV module name at the testbench's root). All shipped templates include this; new suites copied from `verif/template/` inherit it. Without `toplevel:`, `--view tb` silently degrades to the DUT-rooted view.

## When rtl_buddy Changes

- Review recent `rtl_buddy` changes against this template's README, configs, and examples. New user-facing features should be either demonstrated in a focused example or explicitly called out as intentionally out of scope.
- Add or adjust examples in `design/`, `verif/`, `spec/`, `fpv/`, `synth/`, `pnr/`, or `lint/` if the feature needs visible coverage.
- Update the pinned `rtl_buddy` dependency and refresh `uv.lock`.
- Re-run `uv run rb skill install --force` (add `--project` if you use project-scoped skill files) so the installed skill content matches the new rtl_buddy version.
- Re-check feature-dependent dependencies in `pyproject.toml`, especially git-pinned tools such as `rtl-buddy-cdc`, `rtl-buddy-xeno`, and `rtl-buddy-axi-profiler`.
- Commit only the dependency pin (`pyproject.toml` / `uv.lock`) - skill files are gitignored.
