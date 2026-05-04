# AGENTS.md — rtl-buddy-proj-template

## Role

This repo is both:

- a starter RTL project template for `rtl_buddy`
- a runnable reference project that demonstrates the expected repo layout

The project should stay runnable. `design/sandbox/` is the primary working example and should not be left broken.

## This Is A Template Repo

This is a GitHub template repo. New projects are created from it via the "Use this template" button on GitHub — not by forking. It contains template structure, example designs, and `rtl_buddy` integration that downstream projects inherit.

### When Creating A New Project From This Template

Rewrite the following files so they describe the new project, not this template:

- **`README.md`** — replace template descriptions with the new project's name, purpose, and team-specific notes.
- **`CLAUDE.md`** / **`AGENTS.md`** — keep the `rtl_buddy` workflow guidance, but rewrite role and layout sections for the new project.

Remove or update anything that refers to:
- example project names or block names that no longer apply
- private infrastructure, private links, or organization-specific paths
- vendoring or dependency arrangements that the new project does not use

The `rtl_buddy` workflow sections below are worth keeping in downstream projects because they describe how to use the toolchain inside a project repo.

## Important Paths

```text
root_config.yaml
design/regression.yaml
design/cocotb_ex/               # cocotb demo RTL
design/sandbox/
design/template/
spec/template/                  # spec traceability example
verif/cocotb_ex/                # cocotb demo suite
verif/template/
tools/verible/                  # bundled Verible binaries (macOS and x86_64)
pyproject.toml                  # uv-managed project environment and rtl_buddy dependency pin
uv.lock                         # committed lockfile for reproducible project setup
.python-version                 # pinned Python version for uv
```

The `rtl_buddy` agent skill is bundled inside the `rtl_buddy` wheel and materialized on demand with `uv run rb skill install`. Default scope is user-level (`~/.claude/skills/rtl_buddy/`, `~/.codex/skills/rtl_buddy/`); `--project` installs into `.claude/skills/rtl_buddy/` and `.agents/skills/rtl_buddy/` under the project root instead. Both project-level dirs are gitignored.

## Fresh Clone Setup

### Prerequisites (install externally)

- **uv** — install from Astral and make sure it is on `PATH`.
- **Python 3.11** — standard interpreter for this repo.
- **Verilator** — e.g. `brew install verilator` on macOS, or build from source.

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

Verible binaries are bundled under `tools/verible/` — macOS under `macos/active/bin/`, Linux x86_64 under `x86_64/active/bin/`. No separate Verible install is needed.

```bash
# macOS only: strip quarantine xattr from bundled Verible binaries
(cd tools/verible/macos && xattr -rd com.apple.quarantine active)
```

## rtl_buddy Development Overrides

Normal project work should stay on the pinned dependency in `pyproject.toml` / `uv.lock`.

For validating unreleased `rtl_buddy` changes against this project, a standing branch exists:

- **`dev/local-rtl-buddy`** — identical to `main` except `[tool.uv.sources]` in `pyproject.toml` points `rtl_buddy` at `../../../rtl_buddy` in editable mode. Check it out in a worktree (e.g. `.worktrees/dev-local/`) and test against whichever branch is checked out in the sibling `rtl_buddy/` repo. Not meant to be merged.

This branch is the standard place to validate rtl_buddy feature branches end-to-end before publishing a release. Keep `main` on the pinned PyPI dependency so day-to-day clones stay reproducible.

## Validation Commands

Use this repo to validate the project setup and `rtl_buddy` integration.

```bash
# from repo root
uv run rb --machine regression -c design/regression.yaml
uv run rb --machine filelist test_module -c design/sandbox/models.yaml
uv run rb --machine verible syntax design/sandbox/test_module.sv
uv run rb --machine spec list
uv run rb --machine spec check-design
uv run rb --machine spec check-coverage

# from suite dir
cd verif/sandbox
uv run rb --machine test basic

cd ../cocotb_ex
uv run rb --machine test basic
```

`test` and `randtest` are typically run from the suite directory so relative testbench paths resolve correctly.

## When rtl_buddy Changes

- Add or adjust examples in `design/`, `verif/`, and `spec/` if the feature needs visible coverage.
- Update the pinned `rtl_buddy` dependency and refresh `uv.lock`.
- Re-run `uv run rb skill install --force` (add `--project` if you use project-scoped skill files) so the installed skill content matches the new rtl_buddy version.
- Commit only the dependency pin (`pyproject.toml` / `uv.lock`) — skill files are gitignored.
