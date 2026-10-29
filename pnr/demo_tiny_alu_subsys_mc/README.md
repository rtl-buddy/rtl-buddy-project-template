# demo_tiny_alu_subsys on sky130hd — multi-corner signoff

The flat `demo_tiny_alu_subsys` netlist placed, routed and signed off at three
corners in one OpenROAD session: `tt`, `ss` (1.40 V, -40 C) and `ff` (1.95 V,
-40 C). The OpenRAM SRAM is timed from its own Liberty at each corner. One run,
`demo_tiny_alu_subsys_sky130_mc_pnr`, about three minutes.

It shows:

| feature | where | effect |
|---|---|---|
| multi-corner platform | `platform: sky130hd_mc` ([`root_config.yaml`](../../root_config.yaml)) | `corners: [tt, ss, ff]`: each corner is timed in an SDC mode and scene of its own; repair sees every corner |
| per-corner constraints | `constraints:` maps each corner to `constraints_<corner>.sdc` | each corner file sources the shared [`clocks_io.sdc`](clocks_io.sdc) and adds its own clock uncertainty |
| sourced helper under `inputs:` | `inputs: [clocks_io.sdc]` | the helper is fingerprinted, so editing it refuses a `--resume` |
| per-corner macro Liberty | `lib-paths` maps `tt`, `ss` and `ff` to three SRAM Liberty files | each corner times the SRAM from its own file |
| signoff gates | `signoff:` | setup is judged at `ss`, hold at `ff`; negative slack there, or any routing DRC, fails the run |
| staged run | `stages: true` | each stage is its own OpenROAD session with a checkpoint |

## What you need

- `openroad` (26Q4 or newer, which gives each corner its own SDC mode), `yosys`
  and, for `--gds`, `klayout` on `PATH`.
- The sky130hd PDK and the OpenRAM SRAM, then the derived SRAM Liberty:

```sh
./synth/demo_tiny_alu_subsys_hier/download_pdk.sh
./pnr/demo_tiny_alu_subsys_mc/derive_sram_liberty.sh
```

### The SRAM Liberty per corner

The SRAM ships one Liberty, `sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib`.
[`derive_sram_liberty.sh`](derive_sram_liberty.sh) writes three demo copies
of it into the gitignored `pdk/sky130_sram/`. **They are not characterised
data.**

| corner | file | clock-to-output tables | pin `max_transition` |
|---|---|---|---|
| `tt` | `..._TT_derived.lib` | as characterised | 0.5 ns |
| `ss` | `..._SS_derived.lib` | x2 | 0.5 ns |
| `ff` | `..._FF_derived.lib` | x0.7 | 0.5 ns |

The clock-to-output tables are the `cell_rise` and `cell_fall` tables of
`dout0` and `dout1`. Nothing else changes except the library name. The
characterised file limits the address and write-mask pins to a 0.04 ns
transition. On a multi-corner platform OpenROAD's `repair_design` checks every
corner's limit against the fastest buffer at the slowest corner (0.061 ns at
`ss`) and stops with `RSZ-0090`, so every copy raises the limit to the
library's `default_max_transition`, 0.5 ns.

## Run it

```sh
rb synth demo_tiny_alu_subsys_sky130_flat -c synth/demo_tiny_alu_subsys_hier/synth.yaml
rb pnr   demo_tiny_alu_subsys_sky130_mc_pnr -c pnr/demo_tiny_alu_subsys_mc/pnr.yaml -l 1000 --gds
```

or, synthesis included:

```sh
rb pnr demo_tiny_alu_subsys_sky130_mc_pnr -c pnr/demo_tiny_alu_subsys_mc/pnr.yaml -l 1000 --synth --gds
```

`apb_clk` is 40 ns here, where the flat reference in
[`../demo_tiny_alu_subsys_hier/`](../demo_tiny_alu_subsys_hier/README.md) uses
20 ns: at 1.40 V the SRAM read path to `prdata` misses a 20 ns `apb_clk` by
about 5 ns. `cclk` is 25 ns, as there.

## Results

Measured with OpenROAD 26Q4, `threads:` unset. The run passes, DRC-clean, with
5 max-slew violators and 1 max-capacitance violator, which `fail-on` does not
gate.

| corner | setup WNS (ns) | hold WNS (ns) | SRAM `clk1` → `dout1` (ns) |
|---|---|---|---|
| `tt` | +13.19 | +0.30 | 0.35 |
| `ss` | **+5.59** | +0.43 | 0.70 |
| `ff` | +14.31 | **+0.12** | 0.24 |

The SRAM arc is the delay of the SRAM's read on the worst path of each corner,
`u_inner/u_hist_mem/u_sram/clk1` to `dout1[n]`, read from `timing.rpt` in
`artefacts/demo_tiny_alu_subsys_sky130_mc_pnr/`. Each corner reports its own
paths under `Mode: <corner>` and `Corner: <corner>`; the `ss` path also shows
the 0.25 ns setup uncertainty of `constraints_ss.sdc`.

The result row carries the per-corner timing and the signoff record:

```json
"wns_setup_ps": 5590.0,
"wns_hold_ps": 120.0,
"worst_setup_corner": "ss",
"worst_hold_corner": "ff",
"corners": {
  "tt": {"wns_setup_ps": 13190.0, "wns_hold_ps": 300.0, "tns_ps": 0.0, "tns_hold_ps": 0.0},
  "ss": {"wns_setup_ps": 5590.0, "wns_hold_ps": 430.0, "tns_ps": 0.0, "tns_hold_ps": 0.0},
  "ff": {"wns_setup_ps": 14310.0, "wns_hold_ps": 120.0, "tns_ps": 0.0, "tns_hold_ps": 0.0}
},
"signoff": {
  "timing": {
    "setup": {"corners": ["ss"], "wns_ps": 5590.0, "worst_corner": "ss", "unconstrained": false},
    "hold": {"corners": ["ff"], "wns_ps": 120.0, "worst_corner": "ff", "unconstrained": false},
    "verdict": "pass"
  },
  "drc": {"count": 0, "verdict": "pass"},
  "electrical": {"max_slew_violation_count": 5, "max_capacitance_violation_count": 1,
                 "max_fanout_violation_count": 0, "verdict": "not_gated"}
}
```

`wns_setup_ps` and `wns_hold_ps` are the worst over every corner. The
`signoff` gates read only their own corners: setup at `tt` and `ff` and hold
at `tt` and `ss` are reported in `corners` and gate nothing. A failed gate
fails the run with a description such as
`signoff failed: timing (setup WNS -0.1200 ns at ss)`.

Each corner's constraints are also written out:
`demo_tiny_alu_subsys_synth_top.<corner>.routed.sdc`, with the clocks from
`clocks_io.sdc` and that corner's uncertainty.

## Editing a sourced helper

rb does not read the Tcl of an SDC for the files it `source`s. A run lists
them under `inputs:`, and each is fingerprinted with the run's other inputs.
Edit `clocks_io.sdc` after a run and resume it:

```sh
rb pnr demo_tiny_alu_subsys_sky130_mc_pnr -c pnr/demo_tiny_alu_subsys_mc/pnr.yaml -l 1000 \
       --resume latest --from detailed_route
```

The resume is refused, naming the file and both fingerprints:

```text
--resume latest --from detailed_route refused: input extra_inputs differs from what run <run id> (...) read:
[.../pnr/demo_tiny_alu_subsys_mc/clocks_io.sdc (3aebadc47364)] then, [.../pnr/demo_tiny_alu_subsys_mc/clocks_io.sdc (e1f52a175966)] now
```

With the file unchanged, the same command routes from the `global_route`
checkpoint and gives the full run's result. Without `inputs:`, the edit would
go unnoticed and the resumed run would mix constraints from before and after
it.

## Files

| file | what it is |
|---|---|
| `pnr.yaml` | the run |
| `clocks_io.sdc` | clocks, clock groups and I/O delays, shared by every corner |
| `constraints_tt.sdc`, `constraints_ss.sdc`, `constraints_ff.sdc` | each corner's SDC: sources `clocks_io.sdc`, adds its clock uncertainty |
| `derive_sram_liberty.sh` | writes the three derived SRAM Liberty files into `pdk/sky130_sram/` |
