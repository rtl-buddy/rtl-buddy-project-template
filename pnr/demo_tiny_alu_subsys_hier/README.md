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
- **rtl_buddy >= 6.56.0**, which is what `pyproject.toml` pins. Four things in
  this example need it:
  - `cfg-pdks.placement`, `cfg-pdks.dont-use-cells` and `cfg-pdks.pdn-config`
    (rtl-buddy/rtl_buddy#625). An older rtl_buddy loads `root_config.yaml`
    fine and silently ignores all three — which means **no power grid at all**
    in the resulting layout.
  - a list-valued `cfg-pnr-platforms.cts-buffer` (also
    rtl-buddy/rtl_buddy#625), which an older rtl_buddy refuses to load at all.
  - the size-aware shelf macro packer (rtl-buddy/rtl_buddy#632), which is what
    lets the assembly use the flat run's floorplan.
  - macro Liberty inheritance in `rb power` (rtl-buddy/rtl_buddy#630), without
    which every macro reports 0 W.
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

Neither run names a `lib-paths`: since rtl-buddy/rtl_buddy#630 a
`netlist-source: pnr` power run inherits the macro Liberty from the P&R run it
reads, so the SRAM and — in the assembly — both hardened partitions are
characterised rather than counted as zero, and the two totals are comparable.
A macro with no library at all is now the `power.missing_macro_inputs` ERROR.

## Results — flat vs assembled

Measured with OpenROAD `26Q2-911-g731f8ff5a4`, KLayout 0.30.8 and the released
rtl_buddy 6.56.0 wheel this project pins, on the PDK revisions
`download_pdk.sh` pins. `apb_clk` 20 ns, `cclk` 25 ns.

| | flat | csr partition | compute partition | **assembled** |
|---|---|---|---|---|
| verdict | PASS | PASS | PASS | **PASS** |
| standard-cell instances | 1237 | 383 | 299 | 548 |
| die (µm) | 697.4 × 697.4 | 98.9 × 98.9 | 89.5 × 89.5 | **717.0 × 717.0** |
| design area (µm²) | 207 690 | 3 337 | 2 599 | **219 876** |
| core area (µm²) | 456 758 | 7 727 | 6 241 | **483 051** |
| core utilization | 45.5% | 43.2% | 41.6% | **45.5%** |
| setup WNS (ns) | +3.68 | +11.00 | +13.59 | **+3.76** |
| setup TNS (ns) | 0.00 | 0.00 | 0.00 | **0.00** |
| hold WNS (ns) | +0.27 | +0.47 | +0.62 | **+0.28** |
| DRCs | 0 | 0 | 0 | **0** |
| `check_power_grid` VDD/VSS | connected | connected | connected | **connected** |
| GDS | `complete: true` | `complete: true` | `complete: true` | **`complete: true`** |
| static power (mW) | 3.44 | — | — | **3.12** |
| of which the SRAM (mW) | 1.93 | — | — | **1.93** |

Reading it:

- **Timing is essentially identical.** Setup WNS differs by 0.08 ns on a 20 ns
  period, and the worst path is the same one in both — the SRAM's `dout1` out
  to `prdata[9]`, which no partitioning moves. Hold WNS is within 0.01 ns. TNS
  is zero both ways.
- **Design area is +5.9%** assembled (219 876 vs 207 690 µm²). That is the
  partitions' own core-margin and filler being counted at their hardened size
  rather than as loose cells.
- **Core area is +5.7%** (483 051 vs 456 758 µm²) — the assembly uses the same
  `utilization: 0.45, aspect: 1.0, core-margin: 10.0` floorplan as the flat
  reference. The size-aware shelf packer (rtl-buddy/rtl_buddy#632) packs the
  three macros from the bottom-left corner at their real sizes, so the
  floorplan follows the design rather than the placer. The first draft of this
  example needed a 1 624 × 565 µm strip and 872 086 µm² of core — 91% more than
  the flat run — to get the same three macros placed and PDN'd.
- **Power is comparable, with one caveat.** The SRAM reports the same 1.93 mW
  in both runs, because a `netlist-source: pnr` power run now inherits the P&R
  run's macro Liberty (rtl-buddy/rtl_buddy#630). The two hardened partitions
  still contribute 0 W: `write_timing_model` emits timing arcs and no power
  tables, so their abstracts have nothing to characterise. The assembly's
  3.12 mW is therefore the top-level glue plus the SRAM, and the 0.32 mW it
  sits below the flat run is the partitions' own cell power, unmodelled. Both
  runs are free of `power.missing_macro_inputs` and
  `power.unpowered_instances`.

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
| worst setup overall | +3.68 (`u_sram` → `prdata[9]`) | +3.76 (`u_sram` → `prdata[9]`) | +0.08 |
| `psel` → CSR boundary | +15.35 (to an internal D pin) | +15.72 (to the `u_csr` macro) | +0.37 |
| async FIFO → compute boundary | +21.25 (to an internal D pin) | +20.81 (to the `u_compute` macro) | −0.44 |
| worst hold | +0.27 | +0.28 | +0.01 |

Reproduce either column by reading the run's `*.routed.odb` and `*.routed.sdc`
back into OpenROAD with the `read_liberty` lines from its own `pnr.tcl`, then
`set_propagated_clock [all_clocks]` and `estimate_parasitics -global_routing`
before `report_checks` — the same conditions the flow's own final STA uses.

The CSR input check comes out 0.37 ns *less* pessimistic than the flat path it
stands for, and the compute input check 0.44 ns *more*. Both are under 2% of
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
sky130_sram_1kbyte_1rw1r_32x256_8: own_shapes=20517 child_insts=6085  bbox=(0,0;479.78,397.5)
demo_tiny_alu_subsys_csr:          own_shapes=4168  child_insts=4754  bbox=(0,0;98.94,98.94)
demo_tiny_alu_subsys_compute:      own_shapes=2671  child_insts=3607  bbox=(0,0;89.47,89.47)
demo_tiny_alu_subsys_synth_top:    own_shapes=17301 child_insts=46916 bbox=(0,0;716.98,716.98)
```

## rtl_buddy gaps

### Fixed since this example was first drafted

The first draft of this example carried four gaps, all worked around in
configuration. Three of them are gone in rtl_buddy 6.56.0 and the fourth is
moot now the pin is on it — the git history of this directory shows the
work-arounds they needed:

- **Macro placement gave every macro a slot sized for the largest.** The old
  rectangular grid refused `utilization: 0.45, aspect: 1.0` outright ("macros
  do not fit any rectangular grid in the floorplan core") and forced a 1 × 3
  strip, and the thin channels that left around the SRAM then defeated
  `pdngen` (`[ERROR PDN-0179] Unable to repair all channels`). The size-aware
  shelf packer (rtl-buddy/rtl_buddy#632) packs macros from the bottom-left
  corner at their real sizes and keeps `placement.macro-halo` (20 µm by
  default) of clearance around each, which is what the PDN channels need. The
  assembly now uses the flat run's floorplan; see the table above for what
  that saved.
- **`rb power` could not be given a macro's Liberty**, so every macro reported
  exactly 0 W and the flat and assembled totals were not comparable.
  rtl-buddy/rtl_buddy#630 makes a `netlist-source: pnr` power run inherit the
  macro Liberty from the P&R run it reads (and lets a power run add its own
  `lib-paths`), with `power.missing_macro_inputs` as a hard ERROR when a macro
  has no library at all. The SRAM now reports real power (1.93 mW, both ways).
  What is left is not rtl_buddy's: a `write_timing_model` abstract carries no
  power tables, so a hardened partition is still 0 W in its parent's report.
- **`cts-buffer` as a list was a load-time break.** rtl-buddy/rtl_buddy#625
  widens `cfg-pnr-platforms.cts-buffer` to a list (first entry = `-root_buf`);
  before that pin, a list-valued key made `root_config.yaml` refuse to load for
  *every* flow in the repo, so the single-name form was kept with the list in a
  comment. `root_config.yaml` now carries the list.

### 1. Pre-existing: the interface port at the synthesis top

Not introduced here, but it shows up in every log on this design and is worth
naming so it is not mistaken for something this example did. Yosys'
`read_verilog` warns about `apb_intf` at `demo_tiny_alu_subsys_synth_top`:

```text
Warning: Could not find interface instance for `bus' in `demo_tiny_alu_subsys_synth_top'
Warning: Range select [5:0] out of bounds on signal `\apb.paddr': Setting all 6 result bits to undef.
```

Since rtl-buddy/rtl_buddy#629 rtl_buddy classifies that warning itself, through
the `unresolved-interfaces` synth gate (`cfg-synth-tools`, `error` / `warn` /
`allow`, default `warn`). **It fires on the flat and assembly runs here**, once
per unbound instance:

```text
WARNING  interface instance demo_tiny_alu_subsys_synth_top.bus could not be
         bound to the interface port it is passed to; its own port connections
         are dropped from the netlist, leaving any clock or reset it carries
         undriven. frontend: slang binds it correctly
```

The default is deliberately left alone. The warning is **benign on this
design** — the netlist is connected. The out-of-bounds select comes from a
throwaway elaboration made before the interface port is derived; the derived
module carries the full-width `paddr` and the correct slice into the CSR block,
and the design is formally equivalent at its outputs to a `read_slang`
elaboration of the same sources. The only undriven nets are `apb_intf`'s own
`clk` / `rst_n` ports, which this subsystem never reads (it clocks off
`apb_clk` / `apb_rst_n`).

The general hazard behind the warning is real, though: `read_verilog` drops an
interface *instance's* own port connections, so a design that does read
`bus.clk` would synthesize clockless. That is exactly what the gate is for —
a project whose design reads through an interface instance should set
`unresolved-interfaces: error` (or move that run to `frontend: slang`, which
binds it correctly). rtl-buddy/rtl_buddy#628 tracks the remaining work; the
warnings reproduce on `origin/main` with the pre-change RTL, and it is the same
limitation `lint/cdc/cdc.yaml` documents when it puts
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
