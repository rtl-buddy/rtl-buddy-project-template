# Coverview

This template includes a ready-to-run Coverview packaging path for the
Verilator coverage flow.

## What it is for

Use this when you want a browser-friendly coverage package from the
same regression you already run for merged coverage summaries and LCOV
HTML output.

The repo wires the Coverview settings in [`root_config.yaml`](root_config.yaml)
under `cfg-coverview`, and `uv sync` installs the pinned Python-side
packaging dependency (`info-process`).

## Prerequisites

- Run `uv sync --locked --python 3.11`
- Use the Verilator coverage builder mode from this template
- Install any external Coverview viewer/tooling your environment needs

## Generate a package

From the repo root:

```bash
uv run rb -M cov regression -c regression.yaml \
  --coverage-merge --coverage-coverview
```

Common companion command when you also want the LCOV HTML report:

```bash
uv run rb -M cov regression -c regression.yaml \
  --coverage-merge --coverage-html --coverage-coverview
```

## Where outputs land

When you run from the repo root, the merged outputs are written there:

- `coverview_*.zip` - Coverview package
- `coverage_merged.dat` - merged raw coverage database
- `coverage_merged.info` - LCOV info file
- `coverage_merge.html/` - HTML coverage report when `--coverage-html` is used

If you invoke the same command from a suite directory instead, the
outputs land in that directory.

## Related files

- [`root_config.yaml`](root_config.yaml) - builder, coverage, and Coverview config
- [`regression.yaml`](regression.yaml) - suite list used by the merged run
- [`verif/sandbox/README.md`](verif/sandbox/README.md) - sandbox-specific walkthrough
- [`README.md`](README.md) - template overview and end-to-end quick start
