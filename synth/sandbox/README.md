# `synth/sandbox/` — Sandbox Synthesis Example

Synthesis runs for the [tiny-ALU sandbox DUT](../../design/sandbox/).
Demonstrates `rtl_buddy`'s tool-agnostic synthesis flow across three
levels: tech-independent elaboration, tech-mapped Yosys, and tech-mapped
OpenROAD timing analysis against the same open-source standard-cell
library.

## Layout

| File              | Purpose |
|-------------------|---------|
| `synth.yaml`      | Three synthesis runs (`alu_synth_generic`, `alu_synth_nangate45`, `alu_synth_openroad`) |
| `constraints.sdc` | 100 MHz clock + 2 ns input/output delay; Yosys uses the period for ABC timing, OpenROAD reads the full SDC |
| `download_pdk.sh` | Fetches the Nangate45 typical-corner Liberty + LEF assets (~7 MB total) |

## Running

```bash
# tech-independent (no PDK required)
uv run rb synth alu_synth_generic -c synth/sandbox/synth.yaml

# tech-mapped with Yosys (needs Liberty)
./synth/sandbox/download_pdk.sh
uv run rb synth alu_synth_nangate45 -c synth/sandbox/synth.yaml

# tech-mapped with OpenROAD (needs Liberty + LEF, and openroad on PATH)
uv run rb synth alu_synth_openroad -c synth/sandbox/synth.yaml

# discoverable regression — runs everything at reglvl ≤ N
uv run rb synth-regression -c synth_regression.yaml          # default lvl 0 → generic only
uv run rb synth-regression -c synth_regression.yaml -l 1000  # incl. nangate45 + openroad
```

The tech-mapped runs are gated at `reglvl: 1000` so the default
regression stays self-contained. Bump `--reg-level` (alias `-l`) once
the PDK assets are present.

## Wiring

- Tool defaults: `cfg-synth-tools` in [`root_config.yaml`](../../root_config.yaml)
- Library registry: `cfg-synth-libs` in [`root_config.yaml`](../../root_config.yaml)
  (Liberty + LEF paths resolved relative to that file)
- Discoverable regression: [`synth_regression.yaml`](../../synth_regression.yaml)

See `uv run rb docs show concepts/synthesis` for the full feature surface.
