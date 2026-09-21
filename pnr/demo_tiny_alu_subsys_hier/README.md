# demo_tiny_alu_subsys on sky130hd — hierarchical P&R pipeclean

Hardening two partitions of `demo_tiny_alu_subsys` separately, then placing and
routing the top with those two as hard macros next to a real OpenRAM SRAM.

This is the template example rtl-buddy/rtl_buddy#95 step 6 asks for, and it
doubles as that issue's **step 0 spike**: the `harden:` / `blocks:` keys it
specifies do not exist yet, so everything here is wired by hand through the
per-run `lef-paths` / `lib-paths` / `gds-paths` that `rb pnr` already has.
Everything that is hand-wired is called out below, along with the `blocks:`
config that replaces it.

```text
demo_tiny_alu_subsys_synth_top              ← the run's top, both ways
└─ demo_tiny_alu_subsys_top
   ├─ u_csr      demo_tiny_alu_subsys_csr           ← hardened partition A (apb_clk)
   ├─ u_compute  demo_tiny_alu_subsys_compute       ← hardened partition B (cclk)
   │   └─ u_alu  demo_tiny_alu (W=8)
   ├─ u_hist_mem demo_tiny_alu_subsys_mem
   │   └─ u_sram sky130_sram_1kbyte_1rw1r_32x256_8  ← third-party OpenRAM macro (apb_clk)
   └─ u_hs_cmd / u_afifo / u_hs_result / u_sync_*   ← CDC glue, stays as standard cells
```

Both partitions are single-clock, so each one's Liberty abstract is a clean
single-domain timing model and every clock-domain crossing stays in the top's
standard-cell logic, where `rb cdc` already analyses it. The SRAM is at the top
and on `apb_clk` only, so the assembly exercises a hardened partition and a
third-party macro side by side.

## What you need

- `openroad` and `klayout` on `PATH`, and `yosys`.
- An **rtl_buddy carrying rtl-buddy/rtl_buddy#101** — the flow-parameterisation
  keys `cfg-pdks.placement`, `cfg-pdks.dont-use-cells` and
  `cfg-pdks.pdn-config`. An rtl_buddy without them loads `root_config.yaml`
  fine and silently ignores all three, which means **no power grid at all** in
  the resulting layout. The runs here still complete; what they produce is not
  this example. The pinned version in `pyproject.toml` is one of those.
- The PDK and the macro, which are not vendored:

```sh
./synth/demo_tiny_alu_subsys_hier/download_pdk.sh
```

That fetches sky130hd's Liberty, tech + macro LEF, cell GDS and KLayout
technology files into `pdk/sky130hd/`, and the OpenRAM
`sky130_sram_1kbyte_1rw1r_32x256_8` macro — LEF, GDS, Liberty and the
behavioural Verilog model — into `pdk/sky130_sram/`. Both sources are pinned to
a commit. `pdk/` is gitignored.

## The walk-through

Every run is `reglvl: 1000`, so pass `-l 1000` to `rb pnr`.

### 1. Flat reference

The whole design in one netlist, with the SRAM as its only macro. This is what
the assembly is compared against.

```sh
rb synth demo_tiny_alu_subsys_sky130_flat -c synth/demo_tiny_alu_subsys_hier/synth.yaml
rb pnr   demo_tiny_alu_subsys_sky130_flat_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml \
         -l 1000 --gds --png
```

### 2. Harden the two partitions

Each on its own clock, with its own SDC (`constraints_csr.sdc`,
`constraints_compute.sdc`) and its own floorplan, and on the
`sky130hd_tt_block` P&R platform rather than `sky130hd_tt` — see
[Block-level PDN convention](#block-level-pdn-convention).

```sh
rb synth demo_tiny_alu_subsys_sky130_csr     -c synth/demo_tiny_alu_subsys_hier/synth.yaml
rb synth demo_tiny_alu_subsys_sky130_compute -c synth/demo_tiny_alu_subsys_hier/synth.yaml

rb pnr demo_tiny_alu_subsys_sky130_csr_pnr     -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000 --gds --png
rb pnr demo_tiny_alu_subsys_sky130_compute_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000 --gds --png
```

Both carry `gds-mode: strict`: a hardened block with a hole in its layout is
never acceptable, because it is about to be streamed into a parent.

### 3. Write the abstracts

```sh
./pnr/demo_tiny_alu_subsys_hier/harden.sh demo_tiny_alu_subsys_sky130_csr_pnr     demo_tiny_alu_subsys_csr
./pnr/demo_tiny_alu_subsys_hier/harden.sh demo_tiny_alu_subsys_sky130_compute_pnr demo_tiny_alu_subsys_compute
```

`harden.sh` loads the partition's routed `.odb` in OpenROAD and writes, into
`artefacts/<run>/abstract/`:

| file | from | what it is |
|---|---|---|
| `<top>.lef` | `write_abstract_lef -bloat_occupied_layers` | placeable extent, signal pins, VDD/VSS pins, layer blockages |
| `<top>.lib` | OpenSTA `write_timing_model` | boundary setup/hold checks and clock-to-out arcs |
| `<top>.gds` | copied from the run | the layout, for stream-out |
| `abstract.manifest.json` | — | `{path, size, sha256}` for every input and every output |

It builds into a temporary directory and moves it into place only once all
three views exist, so a failed run never leaves a directory with two fresh
views and one stale one. The Liberty files it characterises against are read
back out of the run's own generated `pnr.tcl`, so the model is built against
the same libraries the block was routed against and the script knows nothing
about the platform.

### 4. Assemble

```sh
rb synth demo_tiny_alu_subsys_sky130_asm -c synth/demo_tiny_alu_subsys_hier/synth.yaml
rb pnr   demo_tiny_alu_subsys_sky130_asm_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml \
         -l 1000 --gds --png
```

The synthesis reads `demo_tiny_alu_subsys_sky130_asm.f`, which swaps the two
partitions and the SRAM for port-only `(* blackbox *)` modules — the
`design/demo_synth_macro` pattern — and takes their Liberty and LEF through the
run's `lib-paths` / `lef-paths`. The P&R run names all three macros' LEF,
Liberty and GDS, the PDN ties all three into the top-level grid, and
`gds-mode: strict` passes **with no `gds-allow-empty` entries at all**: every
macro layout here is real, so an empty cell would be a bug rather than a
preview.

### 5. Power (optional)

```sh
rb power demo_tiny_alu_subsys_sky130_flat_power -c power/demo_tiny_alu_subsys_hier/power.yaml -l 1000
rb power demo_tiny_alu_subsys_sky130_asm_power  -c power/demo_tiny_alu_subsys_hier/power.yaml -l 1000
```

Read `power/demo_tiny_alu_subsys_hier/power.yaml` before reading the numbers:
`rb power` cannot be given a macro's Liberty, so every macro reports 0 W.

## Results — flat vs assembled

Measured with OpenROAD `26Q2-911-g731f8ff5a4`, KLayout 0.30.8, rtl_buddy at
`main` plus the rtl_buddy#101 branch, on the PDK revisions
`download_pdk.sh` pins. `apb_clk` 20 ns, `cclk` 25 ns.

| | flat | csr partition | compute partition | **assembled** |
|---|---|---|---|---|
| verdict | PASS | PASS | PASS | **PASS** |
| standard-cell instances | 1237 | 383 | 299 | 548 |
| design area (µm²) | 207 481 | 3 327 | 2 579 | **219 521** |
| core area (µm²) | 456 758 | 7 727 | 6 241 | **872 086** |
| core utilization | 45.4% | 43.1% | 41.3% | 25.2% |
| setup WNS (ns) | +3.99 | +11.00 | +13.59 | **+3.97** |
| setup TNS (ns) | 0.00 | 0.00 | 0.00 | **0.00** |
| hold WNS (ns) | +0.35 | +0.47 | +0.62 | **+0.29** |
| DRCs | 0 | 0 | 0 | **0** |
| `check_power_grid` VDD/VSS | connected | connected | connected | **connected** |
| GDS | `complete: true` | `complete: true` | `complete: true` | **`complete: true`** |
| static power (mW) | 1.42 | — | — | 1.80 |

Reading it:

- **Timing is essentially identical.** Setup WNS differs by 0.02 ns on a 20 ns
  period, and the worst path is the same one in both — the SRAM's `dout1` out
  to `prdata`, which no partitioning moves. Hold WNS is 0.06 ns tighter
  assembled. TNS is zero both ways.
- **Design area is +5.8%** assembled (219 521 vs 207 481 µm²). That is the
  partitions' own core-margin and filler being counted at their hardened size
  rather than as loose cells.
- **Core area is +91%**, and none of that is the design — see the macro-placer
  gap below. The assembly's die is a 1 624 × 565 µm strip because that is the
  only shape the automatic macro grid accepts for these three macros.
- **Power is not comparable** as measured, for the reason in `power.yaml`.

## Step-0 spike findings

These are the questions rtl-buddy/rtl_buddy#95 step 0 asks, answered against
this design.

### Does `write_timing_model` output load cleanly?

**Yes, in both consumers, with no warnings.**

- **Yosys** — `synth.ys` reads each abstract with `read_liberty -lib` and the
  log says `Imported 1 cell types from liberty file` for each, with nothing
  else. rtl_buddy also hands each abstract to a `dfflibmap` pass (it runs one
  per Liberty file); those passes find no sequential cells to map and are
  silent. ABC is given only the platform Liberty, which is correct — a macro
  must never be a mapping target.
- **OpenROAD / OpenSTA at the top** — the abstracts load and produce real
  boundary arcs. `report_checks -to [get_pins u_inner/u_csr/*]` ends paths on
  the macro's input pins against the abstract's setup checks, and
  `report_checks -from [get_pins u_inner/u_compute/*]` starts paths at its
  output pins with clock-to-out delay. No `STA-` warnings about missing arcs or
  unconstrained pins on either block.

**Verdict: OpenSTA `write_timing_model` is fit to be the standard path.**

One caveat worth recording: the model is extracted with the **post-route** SDC,
not the input one, so the clock arrives through the tree CTS actually built and
the block's own insertion delay is in the numbers. `harden.tcl` does that
deliberately; extracting under ideal clocks understates exactly the delay the
parent needs.

### Is the boundary timing defensible against a flat run?

**Yes — within 0.7 ns on a 20–25 ns period, and in both directions**, which is
what rules out a model that is simply optimistic.

| path | flat | assembled | delta |
|---|---|---|---|
| worst setup overall | +3.99 (`u_sram/dout1[5]` → `prdata[5]`) | +3.97 (`u_sram/dout1[9]` → `prdata[9]`) | −0.02 |
| `psel` → CSR boundary | +15.11 (to an internal `dfxtp_1` D pin) | +15.79 (to `u_csr/s_apb_psel`) | +0.68 |
| async FIFO → compute boundary | +21.24 (to an internal D pin) | +21.11 (to `u_compute/fifo_rd_data[18]`) | −0.13 |
| worst hold | +0.31 | +0.29 | −0.02 |

The CSR input check comes out 0.68 ns *less* pessimistic than the flat path it
stands for, and the compute input check 0.13 ns *more*. Both are around 3% of
the period, and the sign changes between blocks, so this looks like extraction
noise rather than a systematic bias. On a design with real margin pressure the
policy question in step 0 — fail the hardening run versus warn with a result
qualifier — would want a tighter bound than this design can demonstrate.

### Do the abstract LEF power pins connect to the top PDN?

**Yes, after fixing the block-level grid** — `check_power_grid` reports
`[INFO PSM-0040] All shapes on net VDD are connected` and the same for VSS, on
the assembly and on all three other runs.

Getting there was the one real design decision in this example.

#### Block-level PDN convention

**A block owns met1 through met4. met5 belongs to whoever instantiates it.**

That rule is implemented as a second PDK entry and a second P&R platform:

| | `sky130hd` / `sky130hd_tt` | `sky130hd_block` / `sky130hd_tt_block` |
|---|---|---|
| `pdn-config` | `pnr/sky130hd/pdn.tcl` | `pnr/sky130hd/pdn_block.tcl` |
| straps | met1 followpins, met4, met5 | met1 followpins, met4 |
| grid exposed on | met5 | **met4** |
| macro grids | yes, `-grid_over_boundary` | none — a leaf block has no macros |
| `routing-layers.signal` | met1-met5 | **met1-met4** |
| used by | flat, assembly | csr, compute |

The two PDK entries share everything else through a YAML merge key in
`root_config.yaml`.

The first attempt used one grid for both, straight from ORFS' sky130hd
`pdn.tcl`, which exposes on met5. The assembly then failed:

```text
[WARNING PDN-0232] The grid "CORE_macro_grid_1 - u_inner/u_csr" (Instance) does not contain any shapes or vias.
[ERROR PDN-0233] Failed to generate full power grid.
```

The cause is the interaction of two things:

1. The parent ties a macro in by running its **met5** straps across the macro
   (`-grid_over_boundary`) and dropping met4/met5 vias onto the macro's power
   pins — so the pins must be on met4 and the macro must be clear on met5.
2. `write_abstract_lef -bloat_occupied_layers` turns **every layer the block
   occupied** into a blockage over the block's whole footprint. A block with
   one power strap on met5 blocks met5 across itself, and the parent's straps
   cannot cross it.

With the block grid on met5, the CSR abstract's `OBS` section listed
`li1 met1 met2 met3 met4 met5` and its VDD/VSS pins were met5 horizontals.
With the block grid stopped at met4, the same abstract's `OBS` lists
`li1 met1 met2 met3 met4` — no met5 — and its VDD/VSS pins are met4 verticals.

The confirmation that this is the right convention and not just a working one:
it is what the third-party macro already does. The OpenRAM SRAM exposes
`vccd1` / `vssd1` on met4 and met3. A hardened partition that does the same is
indistinguishable from it at the top, which is the property the whole flow
depends on.

### Is the SRAM really in the assembled GDS?

Yes. `def2stream.report.json` says `"complete": true` with
`"missing_cells": []` and `"allowed_empty_cells": []`, and the layout itself
carries all three macros:

```text
sky130_sram_1kbyte_1rw1r_32x256_8: own_shapes=20517 child_insts=6085 bbox=(0,0;479.78,397.5)
demo_tiny_alu_subsys_csr:          own_shapes=4120  child_insts=4718 bbox=(0,0;98.94,98.94)
demo_tiny_alu_subsys_compute:      own_shapes=2734  child_insts=3649 bbox=(0,0;89.47,89.47)
demo_tiny_alu_subsys_synth_top:    own_shapes=27815 child_insts=102819 bbox=(0,0;1623.675,565.25)
```

## rtl_buddy gaps

Each of these was hit on this example and worked around in **configuration
only** — nothing in rtl_buddy was modified.

### 1. Macro grid placement gives every macro a slot sized for the largest

`pnr/flow.tcl.template`'s automatic grid (rtl-buddy/rtl_buddy#610) searches for
a rectangular grid in which `max_macro_w <= core_w / cols` and
`max_macro_h <= core_h / rows`, with the maxima taken over *all* macros. With
three macros of 479.78 × 397.50, 98.94 × 98.94 and 89.47 × 89.47 that is:

```text
3 rows x 1 col   core >= 479.78 x 1192.50
2 x 2            core >= 959.56 x  795.00     762 850 um^2
1 row x 3 cols   core >= 1439.34 x 397.50     572 140 um^2
```

At the natural `utilization: 0.45, aspect: 1.0` the core is 695 × 695 µm and
the run fails at macro placement with

```text
Error: pnr.tcl, 125 macros do not fit any rectangular grid in the floorplan core
```

Repro: the assembly run with `floorplan: {utilization: 0.45, aspect: 1.0}`.

### 2. …and the resulting channels are too thin for `pdngen`

Taking the cheapest grid from (1) literally — `utilization: 0.36, aspect: 0.28`,
core 1 470 × 412 µm — places the SRAM with about 7 µm of core above and below
it, and PDN cannot get a met4 strap through:

```text
[WARNING PDN-0178] Remaining channel (972.7900, 416.6700) - (1482.5800, 421.8400) on met4 for nets: VSS
[ERROR PDN-0179] Unable to repair all channels.
```

The committed floorplan is `utilization: 0.25, aspect: 0.34` — core
1 601 × 545 µm — which leaves roughly 73 µm of channel above and below the
SRAM and about 27 µm either side. That is **91% more core area than the flat
run needs** for the same design, all of it spent on the placer's equal-slot
rule.

Both of these are what rtl-buddy/rtl_buddy#95 step 5 (`macro-placement: rtl-mp`)
and rtl-buddy/rtl_buddy#105 (macro anchor / halo / orientation) are for. A
per-macro anchor would let this floorplan be the flat run's.

### 3. `rb power` cannot be given a macro's Liberty

`power.yaml` has no `lib-paths`, and the OpenROAD power backend emits only the
platform's Liberty and the PDK's two LEFs. A macro whose Liberty reaches P&R
through the run's `lib-paths` is in the design, and in
`power_instances.rpt`, with zero power:

```text
Macro                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%
```

```text
   0.00e+00   0.00e+00   0.00e+00   0.00e+00 u_inner/u_hist_mem/u_sram
```

Repro: `rb power demo_tiny_alu_subsys_sky130_flat_power -c power/demo_tiny_alu_subsys_hier/power.yaml -l 1000`,
then read `power.rpt`. This is not specific to hierarchical P&R — it affects
any design with a hard macro, including `demo_synth_macro`.

### 4. `cts-buffer` as a list is a load-time break, not a graceful one

rtl-buddy/rtl_buddy#101 widens `cfg-pnr-platforms.cts-buffer` to accept a list.
The new `cfg-pdks` keys are ignored by an rtl_buddy that does not know them, so
only the runs that need them are affected; a list-valued `cts-buffer`, being a
type change to a key that already exists, makes `root_config.yaml` refuse to
load *at all*:

```text
Method rtl_buddy.config.pnr_platform.PnrPlatformConfigFile.__init__() parameter
cts-buffer=[...] violates type hint <class 'str'>
```

That takes every flow in the repo down, not just this example, so
`root_config.yaml` keeps the single-name form with the list written out in a
comment beside it. Switch once the pin is on a release carrying
rtl-buddy/rtl_buddy#101.

### 5. Pre-existing: the interface port at the synthesis top

Not introduced here, but it shows up in every log on this design and is worth
naming so it is not mistaken for something this example did. Yosys'
`read_verilog` warns about `apb_intf` at `demo_tiny_alu_subsys_synth_top`:

```text
Warning: Could not find interface instance for `bus' in `demo_tiny_alu_subsys_synth_top'
Warning: Range select [5:0] out of bounds on signal `\apb.paddr': Setting all 6 result bits to undef.
```

These are **benign on this design** — the netlist is connected. The
out-of-bounds select comes from a throwaway elaboration made before the
interface port is derived; the derived module carries the full-width `paddr`
and the correct slice into the CSR block, and the design is formally
equivalent at its outputs to a `read_slang` elaboration of the same sources.
The only undriven nets are `apb_intf`'s own `clk` / `rst_n` ports, which this
subsystem never reads (it clocks off `apb_clk` / `apb_rst_n`).

The general hazard behind the first warning is real, though: `read_verilog`
drops an interface *instance's* own port connections, so a design that does
read `bus.clk` would synthesize clockless. rtl-buddy/rtl_buddy#628 tracks
gating on it; the warnings reproduce on `origin/main` with the pre-change RTL,
and it is the same limitation `lint/cdc/cdc.yaml` documents when it puts
`demo_tiny_alu_subsys_lint` on the pyslang frontend.

## After rtl-buddy/rtl_buddy#95

Everything in the walk-through that is hand-wired collapses into config.

`harden.sh` and `harden.tcl` are deleted, and each partition's P&R entry gains
one key:

```yaml
  - name: "demo_tiny_alu_subsys_sky130_csr_pnr"
    # ... unchanged ...
    platform: "sky130hd_tt_block"
    harden: true                        # writes artefacts/<run>/abstract/
    gds-mode: strict
```

The assembly's three `lef-paths`, three `lib-paths` and three `gds-paths`
become one `blocks:` list — the SRAM stays where it is, because it is a
third-party macro and not a block this project hardens:

```yaml
  - name: "demo_tiny_alu_subsys_sky130_asm_pnr"
    # ... unchanged ...
    blocks:
      - name: demo_tiny_alu_subsys_csr
        pnr: demo_tiny_alu_subsys_sky130_csr_pnr
        pnr-path: pnr.yaml
      - name: demo_tiny_alu_subsys_compute
        pnr: demo_tiny_alu_subsys_sky130_compute_pnr
        pnr-path: pnr.yaml
    lef-paths: ["../../pdk/sky130_sram/sky130_sram_1kbyte_1rw1r_32x256_8.lef"]
    lib-paths: ["../../pdk/sky130_sram/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"]
    gds-paths: ["../../pdk/sky130_sram/sky130_sram_1kbyte_1rw1r_32x256_8.gds"]
    gds-mode: strict
```

and `rb pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000` with no run name
orders the partitions before the assembly on its own.

Three things this project-level version cannot do, which are the point of the
issue's steps 1–3:

- **Fingerprint the real input set.** `abstract.manifest.json` records the
  netlist, DEF, SDC and ODB it can see in the artefact directory, and the three
  outputs. It cannot record the PDK files, the platform and corner, or the
  rtl_buddy version, because a project script does not know them. Step 1 does.
- **Refuse a stale abstract.** Nothing here re-checks the manifest. Edit a
  partition's RTL, re-run only the assembly, and it consumes yesterday's
  abstract without a word. Step 3 makes that a FAIL naming the block.
- **Order the runs.** The sequence above is prose in this file. Step 4 makes it
  a topological sort.

## Files

| file | what it is |
|---|---|
| `synth/demo_tiny_alu_subsys_hier/download_pdk.sh` | fetches sky130hd and the OpenRAM macro into the gitignored `pdk/` |
| `synth/demo_tiny_alu_subsys_hier/synth.yaml` | the four synthesis runs |
| `synth/demo_tiny_alu_subsys_hier/constraints_flat.sdc` | top-level constraints, shared by the flat and assembly runs |
| `synth/demo_tiny_alu_subsys_hier/constraints_csr.sdc` | partition A's single-clock constraints |
| `synth/demo_tiny_alu_subsys_hier/constraints_compute.sdc` | partition B's single-clock constraints |
| `pnr/demo_tiny_alu_subsys_hier/pnr.yaml` | the four P&R runs |
| `pnr/demo_tiny_alu_subsys_hier/harden.sh` | abstract generation — the stand-in for `harden: true` |
| `pnr/demo_tiny_alu_subsys_hier/harden.tcl` | the OpenROAD half of it |
| `pnr/sky130hd/pdn.tcl` | top-level power grid, with macro grids |
| `pnr/sky130hd/pdn_block.tcl` | block-level power grid — the convention above |
| `power/demo_tiny_alu_subsys_hier/power.yaml` | post-P&R power for the flat and assembled runs |
| `design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_mem.sv` | technology wrapper — flop array or SRAM macro |
| `design/demo_tiny_alu_subsys/*_bb.sv` | port-only blackboxes for the two partitions and the SRAM |
