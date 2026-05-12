# demo_tiny_alu_subsys — OpenROAD P&R

Prototype physical-implementation flow for `demo_tiny_alu_subsys` on
Nangate45. Drives a locally installed `openroad` through Tcl scripts;
this is a hand-rolled prototype intended to prove the flow ahead of an
eventual `rb pnr` subcommand.

## Prerequisites

1. **OpenROAD** on `PATH` (`brew install --HEAD openroad` or build from
   source).
2. **Liberty + LEF** fetched into `pdk/nangate45/`:
   ```bash
   ./synth/demo_tiny_alu_subsys/download_pdk.sh
   ```
3. **Tech-mapped netlist** from Yosys:
   ```bash
   uv run rb synth demo_tiny_alu_subsys_synth_nangate45 \
       -c synth/demo_tiny_alu_subsys/synth.yaml
   ```

## Run

```bash
./pnr/demo_tiny_alu_subsys/run.sh
```

Outputs land in `pnr/demo_tiny_alu_subsys/artefacts/`:

| File | Contents |
|---|---|
| `openroad.log` | Full tool log |
| `<top>.def` | Routed DEF |
| `<top>.routed.v` | Post-route gate netlist |
| `<top>.routed.sdc` | Post-route SDC |
| `timing.rpt` | Worst-path timing report |
| `route.drc.rpt` | DRC violations (empty = clean) |

## Reference results (May 2026)

| Metric | Value |
|---|---|
| Std-cell instances | 1392 |
| Filler instances   | 1875 |
| Die area           | 79.7 × 79.7 µm² |
| Effective utilisation | 57 % |
| WNS (max / setup)  | +4.35 ns |
| WNS (min / hold)   | +0.08 ns |
| TNS                | 0 |
| DRCs               | 0 |

## GDS streamout

`write_gds` is not guaranteed available in every OpenROAD build. When it
is missing, the flow prints a KLayout invocation that consumes the
routed DEF + the standard-cell GDS in `pdk/nangate45/gds/`. The
`def2gds.py` script lives in OpenROAD-flow-scripts under
`flow/util/def2gds.py` if you want to wire it up locally.

## Files

- `config.tcl` — block-level variables (paths, utilization, cell names)
- `flow.tcl`   — the stage pipeline (read → floorplan → place → CTS → route → streamout)
- `run.sh`     — entry point with prerequisite checks
