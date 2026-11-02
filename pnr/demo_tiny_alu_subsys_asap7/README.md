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

- **rtl_buddy** as pinned in `pyproject.toml`. The runs use the platform Tcl
  hooks (rtl-buddy/rtl_buddy#716), `post-cts-setup-repair` and
  `routing-layer-adjustment` (#717), the routed and physical cell counts
  (#718), and list-valued corners for ASAP7's split Liberty, read in ps and
  gzipped (#699).
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

# power: the synthesised netlist, then the routed design of ..._compute_pnr
rb power -c power/demo_tiny_alu_subsys_asap7/power.yaml -l 1000
```

Each run takes about 30 seconds. Outputs land in `artefacts/<run>/`.

## How it is wired

| File | Role |
| --- | --- |
| [`root_config.yaml`](../../root_config.yaml) `cfg-pdks` `asap7` | ORFS `flow/platforms/asap7/config.mk`, key by key: site, split TT Liberty, LEF, ties, fill and decap cells, pin layers, density, dont-use cells, PDN, RCX rules, and the four hooks |
| `cfg-synth-platforms` `asap7_tt` | The synthesis platform |
| `cfg-pnr-platforms` `asap7_tt` | CTS buffers, routing layers M2-M7 (clock M4-M7), `routing-layer-adjustment: 0.25` |
| `cfg-pnr-platforms` `asap7_tt_no_cts_setup_repair` | The same, plus `post-cts-setup-repair: false` |
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

Measured with the rtl_buddy that `pyproject.toml` pins, OpenROAD 26Q4 and
Yosys from rtl-buddy-tools, and ORFS at the commit pinned in `download_pdk.sh`.

| Run | Clock | Platform | Cells in / routed / physical | Area | WNS setup | TNS setup | WNS hold | DRC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `..._compute_pnr` | 600 ps | `asap7_tt` | 330 / 359 / 534 | 43 µm² | +71.5 ps | 0 | +62.6 ps | 0 |
| `..._compute_tight_pnr` | 250 ps | `asap7_tt_no_cts_setup_repair` | 330 / 395 / 533 | 46 µm² | −132.7 ps | −1002.6 ps | +8.9 ps | 0 |
| `..._compute_tight_setup_pnr` | 250 ps | `asap7_tt` | 330 / 409 / 513 | 48 µm² | −120.3 ps | −966.5 ps | +8.7 ps | 0 |

Synthesis alone reports 330 cells, 38.96 µm² and +321.7 ps at 600 ps; it does
not see wire RC or the high-fanout nets that placement exposes.

What to look for in `artefacts/<run>/pnr.log`:

- `>>> Platform Tcl`, `>>> Layer RC`, `>>> Routing tracks` and `>>> Tap and
  endcap cells`, one per hook.
- `[INFO TAP-0004] Inserted 70 endcaps.` No tap cells are needed at this size:
  the core is narrower than the 25 µm tap distance.
- No `EST-0018` / `CTS-0104` warnings, and one `EST-0027`, from the setup
  repair at the end of the floorplan, which runs before placement and so on
  wire load models. They are what OpenROAD prints when every wire has zero
  RC, which is what the ASAP7 tech LEF gives without `layer-rc-tcl`.
- No `STA-1212` warnings from the Liberty reads.
- `RB-CELL-COUNT: routed 359 physical 534`. The physical count is the 70
  endcaps plus the 464 filler and decap cells that the `fill-cells` patterns
  match.
- `route.drc.rpt` empty.

The 250 ps pair shows what `post-cts-setup-repair` adds. The flow repairs
setup at the end of the floorplan, after CTS and after global route, as ORFS
does; `asap7_tt_no_cts_setup_repair` turns off only the repair after CTS, so
its setup violations wait for the global-route repair. With setup repair
after CTS, 14 more cells and 2 µm² more area recover 12 ps of WNS and 36 ps of
TNS. Neither closes at 250 ps; the clock is over-constrained on purpose.

Without `tracks-tcl` the run stops at `make_tracks` with `IFP-0039`.

## Power

[`power/demo_tiny_alu_subsys_asap7/power.yaml`](../../power/demo_tiny_alu_subsys_asap7/power.yaml)
analyses the same partition on the same `asap7_tt` platform, so OpenROAD's
power analysis reads the corner the way synthesis and P&R do: five Liberty
files, three of them `.lib.gz`, in ps (rtl-buddy/rtl_buddy#699).

| Run | Netlist | Activity | Total | Internal | Switching | Leakage | Clock |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `..._power_static` | synthesised | Liberty defaults | 205 µW | 138 µW | 67 µW | 28 nW | 0 |
| `..._power_postpnr` | routed `..._compute_pnr`, SPEF | 0.2 toggle, 0.5 duty | 191 µW | 117 µW | 74 µW | 24 nW | 40 µW |

Only the post-P&R run has a clock tree to report. It warns that the 534
physical-only instances (eight masters: the `DECAP*` and `FILLER*` cells and
the `TAPCELL` endcaps) have no Liberty power data and are reported at 0 W. That is expected: the TT Liberty
does not characterise them.
