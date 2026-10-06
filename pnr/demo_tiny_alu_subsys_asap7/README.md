# demo_tiny_alu_subsys on ASAP7 — a flat P&R example on an ORFS platform

The `demo_tiny_alu_subsys_compute` partition (the ALU datapath, one clock)
synthesised and placed and routed on **ASAP7**, the ASU/ARM predictive 7nm PDK,
RVT cells at the TT corner. It is the same partition the
[sky130hd hierarchical example](../demo_tiny_alu_subsys_hier/README.md) hardens,
so the two processes can be compared on one netlist.

ASAP7 is taken straight from OpenROAD-flow-scripts (ORFS)
`flow/platforms/asap7`, and needs the four platform Tcl hooks rtl_buddy sources
at the step ORFS sources its own (`platform-tcl`, `layer-rc-tcl`, `tracks-tcl`,
`tapcell-tcl`; rtl-buddy/rtl_buddy#716). This example is the reference
configuration for them.

## What you need

- **rtl_buddy >= 6.70.0**, which `pyproject.toml` pins: rtl-buddy/rtl_buddy#716 (the Tcl hooks), #717
  (`post-cts-setup-repair`, `routing-layer-adjustment`, hold TNS) and #718
  (`routed_cell_count` / `physical_cell_count`), on top of #699 (list-valued
  corners for ASAP7's split Liberty, the ps Liberty `time_unit`, gzipped
  Liberty).
- **Yosys** and **OpenROAD** on `PATH`. **KLayout** only for `--gds` / `--png`.
- The PDK, fetched once per checkout into the gitignored `pdk/asap7/`:

  ```bash
  ./synth/demo_tiny_alu_subsys_asap7/download_pdk.sh
  ```

  About 12 MB from ORFS at a pinned commit: the five RVT TT NLDM Liberty
  files, the 1x tech and cell LEF, the cell GDS, the KLayout tech, the RCX
  rules, and the ORFS Tcl the hooks use. Paths under `pdk/asap7/` mirror
  `flow/platforms/asap7/` exactly.

## Run it

```bash
rb synth demo_tiny_alu_subsys_asap7_compute -c synth/demo_tiny_alu_subsys_asap7/synth.yaml
rb pnr demo_tiny_alu_subsys_asap7_compute_pnr -c pnr/demo_tiny_alu_subsys_asap7/pnr.yaml -l 1000

# or every run in this file, synthesis included
rb pnr -c pnr/demo_tiny_alu_subsys_asap7/pnr.yaml -l 1000 --synth

# add --gds --png to stream out GDS and render it with KLayout
```

Each run takes about 30 seconds. Outputs land in `artefacts/<run>/`.

## How it is wired

| File | Role |
| --- | --- |
| [`root_config.yaml`](../../root_config.yaml) `cfg-pdks` `asap7` | ORFS `flow/platforms/asap7/config.mk`, key by key: site, split TT Liberty, LEF, ties, fill and decap cells, pin layers, density, dont-use cells, PDN, RCX rules, and the four hooks |
| `cfg-synth-platforms` `asap7_tt` | The synthesis platform |
| `cfg-pnr-platforms` `asap7_tt` | CTS buffers, routing layers M2-M7 (clock M4-M7), `routing-layer-adjustment: 0.25` |
| `cfg-pnr-platforms` `asap7_tt_setup_repair` | The same, plus `post-cts-setup-repair: true` |
| [`../asap7/tapcell.tcl`](../asap7/tapcell.tcl) | `tapcell-tcl`: ORFS' `openRoad/tapcell.tcl` with `TAP_CELL_NAME` and `MACRO_ROWS_HALO_X/Y` filled in, since rb sources hooks with no ORFS environment |
| [`../asap7/pdn.tcl`](../asap7/pdn.tcl) | `pdn-config`: ORFS' `grid_strategy-M1-M2-M5-M6.tcl`, committed like `../sky130hd/pdn.tcl` |
| `pdk/asap7/liberty_suppressions.tcl` | `platform-tcl`, used verbatim: suppresses STA-1212 before the Liberty reads |
| `pdk/asap7/setRC.tcl` | `layer-rc-tcl`, used verbatim: per-layer wire RC (the tech LEF has none) |
| `pdk/asap7/openRoad/make_tracks.tcl` | `tracks-tcl`, used verbatim: ASAP7's multi-offset M2 tracks |
| [`../../synth/demo_tiny_alu_subsys_asap7/`](../../synth/demo_tiny_alu_subsys_asap7/) | `synth.yaml`, the SDCs, and `download_pdk.sh` |

The SDCs are in **ps**: the ASAP7 Liberty `time_unit` is 1 ps and SDC values
are read in the Liberty's unit. rb reports every time in ps either way.

Only the two files that had to change are vendored, each with a header naming
its ORFS source file and commit. The other three hooks point at the downloaded
upstream files.

## Expected results

Measured with the released rtl_buddy 6.70.0 wheel this project pins, OpenROAD and Yosys
from rtl-buddy-tools, ORFS at the commit pinned in `download_pdk.sh`.

| Run | Clock | Platform | Cells in / routed / physical | Area | WNS setup | TNS setup | WNS hold | DRC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `..._compute_pnr` | 600 ps | `asap7_tt` | 330 / 359 / 610 | 43 µm² | +63.6 ps | 0 | +63.2 ps | 0 |
| `..._compute_tight_pnr` | 250 ps | `asap7_tt` | 330 / 360 / 611 | 43 µm² | −286.4 ps | −2432.5 ps | +7.5 ps | 0 |
| `..._compute_tight_setup_pnr` | 250 ps | `asap7_tt_setup_repair` | 330 / 385 / 616 | 46 µm² | −126.7 ps | −908.7 ps | +7.5 ps | 0 |

Synthesis alone reports 330 cells, 38.96 µm² and +321.7 ps at 600 ps; it does
not see wire RC or the high-fanout nets that placement exposes.

What to look for in `artefacts/<run>/pnr.log`:

- `>>> Platform Tcl`, `>>> Layer RC`, `>>> Routing tracks` and `>>> Tap and
  endcap cells`, one per hook.
- `[INFO TAP-0004] Inserted 70 endcaps.` No tap cells are needed at this size:
  the core is narrower than the 25 µm tap distance.
- No `EST-0018` / `EST-0027` / `CTS-0104` warnings. They are what OpenROAD
  prints when every wire has zero RC, which is what the ASAP7 tech LEF gives
  without `layer-rc-tcl`.
- No `STA-1212` warnings from the Liberty reads.
- `RB-CELL-COUNT: routed 359 physical 610`. The physical count is the 70
  endcaps plus the filler and decap cells that the `fill-cells` patterns match.
- `route.drc.rpt` empty.

The 250 ps pair shows what `post-cts-setup-repair` buys: the default flow only
repairs hold after CTS, so the setup violations stay as synthesis left them.
With setup repair after CTS, 25 more cells and 3 µm² more area recover 160 ps of
WNS and about 60% of the TNS. Neither closes at 250 ps; the clock is
over-constrained on purpose.

Without `tracks-tcl` the run stops at `make_tracks` with `IFP-0039`.
