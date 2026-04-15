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
design/sandbox/
design/template/
tools/verible/                 # bundled Verible binaries (macOS and x86_64)
pyproject.toml                 # uv-managed project environment and rtl_buddy dependency pin
uv.lock                        # committed lockfile for reproducible project setup
.python-version                # pinned Python version for uv
```

Skill files can be installed into `.agents/skills/rtl_buddy/` and `.claude/skills/rtl_buddy/` with `uv run rb install-skill`; both are gitignored (generated from the installed package).

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

If you need the local agent skill files, install them explicitly:

```bash
uv run rb install-skill
```

Verible binaries are bundled under `tools/verible/` — macOS under `macos/active/bin/`, Linux x86_64 under `x86_64/active/bin/`. No separate Verible install is needed.

```bash
# macOS only: strip quarantine xattr from bundled Verible binaries
(cd tools/verible/macos && xattr -rd com.apple.quarantine active)
```

## rtl_buddy Development Overrides

Normal project work should stay on the pinned dependency in `pyproject.toml` / `uv.lock`.

If you need to validate an unreleased `rtl_buddy` change against this project:

1. Check out the source repo separately, usually as `../rtl_buddy/`.
2. Temporarily change `pyproject.toml` to point `rtl_buddy` at that local path in editable mode.
3. Run `uv lock` and `uv sync --python 3.11`.
4. Validate the project.
5. Revert the local override before committing this repo.

Keep that override workflow separate from normal project setup so day-to-day installs stay fast and reproducible.

## Validation Commands

Use this repo to validate the project setup and `rtl_buddy` integration.

```bash
# from repo root
uv run rb --machine regression -c design/regression.yaml
uv run rb --machine filelist test_module -c design/sandbox/models.yaml
uv run rb --machine verible syntax design/sandbox/test_module.sv

# from suite dir
cd verif/sandbox
uv run rb --machine test basic
```

`test` and `randtest` are typically run from the suite directory so relative testbench paths resolve correctly.

## When rtl_buddy Changes

- Add or adjust examples in `design/` if the feature needs visible coverage.
- Update the pinned `rtl_buddy` dependency and refresh `uv.lock`.
- Re-run `uv run rb install-skill --force` if you rely on the local skill files and need them refreshed after updating the pin.
- Commit only the dependency pin (`pyproject.toml` / `uv.lock`) — skill files are gitignored.
