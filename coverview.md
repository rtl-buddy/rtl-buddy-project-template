# Coverview

[Coverview](https://github.com/rtl-buddy/coverview) is a browser-based coverage dashboard for visualizing LCOV coverage data from `rtl_buddy` regressions.

## Prerequisites

- Node.js and npm

## Installation

```bash
git clone https://github.com/rtl-buddy/coverview.git
cd coverview
npm install
```

This repo's default flow is to use the `rtl-buddy/coverview` fork directly, then run the local development server with `npm run dev`.

## Generating coverage data

Run a coverage regression with `--coverage-coverview` to produce the Coverview zip:

```bash
cd verif/demo_tiny_alu
uv run rb -M cov regression --coverage-merge --coverage-html --coverage-coverview -c regression.yaml
```

Output: `verif/demo_tiny_alu/coverview_regression.zip`

## Viewing coverage

**Development server (hot reload):**

```bash
cd coverview
npm run dev
```

Open the URL shown in the terminal, then load `coverview_regression.zip` in the browser.

**Standalone (no server):**

```bash
cd coverview
npm run build
./embed.py --inject-data <path-to-coverview-data-dir>
```

Open the resulting HTML file directly in a browser.
