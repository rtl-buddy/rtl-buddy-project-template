# Coverview

[Coverview](https://github.com/rtl-buddy/coverview) is a browser-based
coverage dashboard for visualizing LCOV coverage data from `rtl_buddy`
regressions. This template ships a ready-to-run packaging path for the
Verilator coverage flow.

## What it is for

Use this when you want a browser-friendly coverage package from the
same regression you already run for merged coverage summaries and LCOV
HTML output.

The repo wires the Coverview settings in
[`root_config.yaml`](root_config.yaml) under `cfg-coverview`, and
`uv sync` installs the pinned Python-side packaging dependency
(`info-process`).

## Prerequisites

- Run `uv sync --locked --python 3.11`
- Use the Verilator coverage builder mode from this template
- Node.js and npm (for the Coverview viewer itself)

### Install the viewer

```bash
git clone https://github.com/rtl-buddy/coverview.git
cd coverview
npm install
```

This repo's default flow is to use the `rtl-buddy/coverview` fork
directly, then run the local development server with `npm run dev`.

## Generate a package

From the repo root:

```bash
uv run rb -M cov regression -c regression.yaml \
  --coverage-merge --coverage-html --coverage-coverview \
  --coverage-source-summary
```

`--coverage-source-summary` (rtl_buddy >= 6.58) adds
`Coverage source points <metric>:` lines scoring each source point once,
with the per-elaboration figure in brackets. They differ only where a
module is elaborated more than once (e.g. `demo_tiny_alu_subsys`); for
`demo_tiny_alu` alone they coincide.

## Where outputs land

When you run from the repo root, the merged outputs are written there:

- `coverview_regression.zip` — Coverview package
- `cov_dir/coverage_merged.dat` — merged raw coverage database
- `cov_dir/coverage_merged.info` — LCOV info file
- `coverage_merge.html/` — HTML coverage report when `--coverage-html` is used
- `cov_dir/manifest.json` — run manifest: `totals` (per elaboration),
  `source_totals` (per source point), and the merge verdict
  `merge_failed` / `failed_metrics`

## Reading a failed merge

The summary line uses two different "no number" tokens:

| Token | Meaning |
|-------|---------|
| `UNSP` | Not instrumented — this build never measured the metric. |
| `FAIL` | Measured, then lost: `verilator_coverage --write` (the only source for toggle, expression, and functional coverage) failed. |

```text
Merged Coverage: L:0.92 B:0.95 T:FAIL F:FAIL
```

A failed merge sets `merge_failed: true` and lists the lost metrics in
`failed_metrics` in `cov_dir/manifest.json`, and the run **exits 1** —
after results, the coverage model, and the manifest are written, so
nothing already produced is lost. Line and branch still report, since
they come from the per-test LCOV exports. Check `merge_failed` before
comparing manifest `totals` against the console summary.

If you invoke the same command from a suite directory instead, the
outputs land in that directory.

## Viewing coverage

**Development server (hot reload):**

```bash
cd coverview
npm run dev
```

Open the URL shown in the terminal, then load
`coverview_regression.zip` in the browser.

**Standalone (no server):**

```bash
cd coverview
npm run build
./embed.py --inject-data <path-to-coverview-data-dir>
```

Open the resulting HTML file directly in a browser.

## Related files

- [`root_config.yaml`](root_config.yaml) — builder, coverage, and Coverview config
- [`regression.yaml`](regression.yaml) — suite list used by the merged run
- [`verif/demo_tiny_alu/README.md`](verif/demo_tiny_alu/README.md) — demo-block walkthrough
- [`README.md`](README.md) — template overview and end-to-end quick start
