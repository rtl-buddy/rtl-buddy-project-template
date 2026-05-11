# `synth/demo_sandbox/` — Sandbox Synthesis Example

Yosys-based synthesis runs for the [tiny-ALU sandbox DUT](../../design/demo_sandbox/).
Demonstrates `rtl_buddy`'s tool-agnostic synthesis flow: tech-independent
elaboration plus tech-mapped synthesis against an open-source standard
cell library.

## Layout

| File              | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| `synth.yaml`      | Two synthesis runs (`demo_sandbox_alu_synth_generic`, `demo_sandbox_alu_synth_nangate45`) |
| `constraints.sdc` | 100 MHz clock + 2 ns input/output delay; ABC reads the period for timing-driven mapping |
| `download_pdk.sh` | Fetches the Nangate45 typical-corner Liberty file (~6 MB)      |

## Running

```bash
# tech-independent (no PDK required)
uv run rb synth demo_sandbox_alu_synth_generic -c synth/demo_sandbox/synth.yaml

# tech-mapped (needs Liberty)
./synth/demo_sandbox/download_pdk.sh
uv run rb synth demo_sandbox_alu_synth_nangate45 -c synth/demo_sandbox/synth.yaml

# discoverable regression — runs everything at reglvl ≤ N
uv run rb synth-regression -c synth_regression.yaml          # default lvl 0 → generic only
uv run rb synth-regression -c synth_regression.yaml -l 1000  # incl. nangate45
```

The tech-mapped run is gated at `reglvl: 1000` so the default regression
stays self-contained. Bump `--reg-level` (alias `-l`) once the PDK is
present.

## Wiring

- Tool defaults: `cfg-synth-tools` in [`root_config.yaml`](../../root_config.yaml)
- Liberty registry: `cfg-synth-libs` in [`root_config.yaml`](../../root_config.yaml)
  (paths resolved relative to that file)
- Discoverable regression: [`synth_regression.yaml`](../../synth_regression.yaml)

See `uv run rb docs show concepts/synthesis` for the full feature surface.
