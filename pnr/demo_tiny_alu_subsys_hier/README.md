# demo_tiny_alu_subsys on sky130hd — hierarchical P&R pipeclean

Hardening two partitions of `demo_tiny_alu_subsys` separately, then placing and
routing the top with those two as hard macros next to a real OpenRAM SRAM.

This is the template example rtl-buddy/rtl_buddy#95 step 6 asks for, and the
record of that issue's **step 0 spike**. Each partition's P&R run sets
`harden: true`, which publishes its abstract LEF, Liberty timing model and GDS;
the assembly's synthesis and P&R entries name the two partitions under
`blocks:` and take those views from there. Nothing is wired by hand except the
third-party SRAM.

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
- **rtl_buddy >= 6.70.0** (`pyproject.toml` pins 6.77.0; 6.70.0 is needed for
  the sky130hd wire RC below; the rest needs 6.65.0). 6.63.0 added
  `harden:` and `blocks:` (rtl-buddy/rtl_buddy#95); 6.64.0 the standard-cell
  keep-out around macros that keeps the assembly DRC-clean
  (`cfg-pdks.placement.macro-cell-halo`, rtl-buddy/rtl_buddy#673); 6.65.0 the
  whole-suite `rb pnr` that orders blocks before the assembly, with `--synth`
  and `-j`, `floorplan.macro-placement: rtl-mp`, and an `rb power` that no
  longer zeroes the switching the partitions drive (rtl-buddy/rtl_buddy#684).
  The sky130hd wire RC (`cfg-pdks.layer-rc-tcl`) needs 6.70.0
  (rtl-buddy/rtl_buddy#716); an older rtl_buddy ignores the key and runs
  repair and CTS on zero-RC wires. The rest of the example needs what 6.56.0 added:
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

### All of it in one command

```sh
rb pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000 --synth -j 2 --gds
```

`rb pnr` with no run name runs every entry in `pnr.yaml`, each partition before
the assembly runs that consume it (rtl-buddy/rtl_buddy#95). `--synth` runs
each P&R run's own synthesis just before it, which is what puts the assembly's
synthesis *after* the partitions are hardened: it reads their abstracts. `-j 2`
hardens the two partitions side by side. From an empty tree that is every
synthesis and every P&R below, in under seven minutes on a laptop. A partition
that fails leaves the assembly runs `FAIL` with `fail_stage: blocked`, naming
the partition, rather than running them against a missing abstract.

The steps below are the same runs one at a time, and what each one does.

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

Both set `harden: true`, which forces a strict stream-out — a hardened block
with a hole in its layout is never acceptable, because it is about to be
streamed into a parent — and, once the run passes, publishes into
`artefacts/<run>/abstract/`:

| file | from | what it is |
|---|---|---|
| `<top>.lef` | `write_abstract_lef -bloat_occupied_layers` | placeable extent, signal pins, VDD/VSS pins, layer blockages |
| `<top>.lib` | OpenSTA `write_timing_model` | boundary setup/hold checks and clock-to-out arcs |
| `<top>.gds` | the run's strict stream-out | the layout, for stream-out |
| `abstract.manifest.json` | — | technology, config digest, and `{path, size, sha256}` for every input and output |

The LEF and the Liberty model are written in the P&R session itself, after the
routed database, so the model is characterised against the libraries the
block was routed against, with the clock tree CTS built and the final
parasitics. The directory appears only once all three views and the manifest
exist; a run that cannot produce one fails with `fail_stage: abstract` and
leaves none.

### 3. Assemble

```sh
rb synth demo_tiny_alu_subsys_sky130_asm -c synth/demo_tiny_alu_subsys_hier/synth.yaml
rb pnr   demo_tiny_alu_subsys_sky130_asm_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml \
         -l 1000 --gds --png
```

The synthesis reads `demo_tiny_alu_subsys_sky130_asm.f`, which swaps the two
partitions and the SRAM for port-only `(* blackbox *)` modules — the
`design/demo_synth_macro` pattern. It takes the SRAM's Liberty and LEF through
`lib-paths` / `lef-paths` and the partitions' through `blocks:`. The P&R run
does the same for all three macros' LEF, Liberty and GDS, the PDN ties all
three into the top-level grid, and
`gds-mode: strict` passes **with no `gds-allow-empty` entries at all**: every
macro layout here is real, so an empty cell would be a bug rather than a
preview.

Before either tool starts, each block's abstract is checked against the
partition as it is now: every file its manifest recorded — RTL, netlist, SDC,
Liberty, LEF, PDN snippet — and the three views are fingerprinted again, and
the partition's configuration is compared by digest. Edit
`constraints_csr.sdc`, re-run only the assembly, and it fails:

```text
block 'demo_tiny_alu_subsys_csr' is stale: sdc synth/demo_tiny_alu_subsys_hier/constraints_csr.sdc changed
— re-run `rb pnr demo_tiny_alu_subsys_sky130_csr_pnr -c …/pnr.yaml`, or pass --accept-stale
```

`--accept-stale` on `rb synth` / `rb pnr` runs anyway and says so in the
result.

### 4. Power (optional)

```sh
rb power demo_tiny_alu_subsys_sky130_flat_power -c power/demo_tiny_alu_subsys_hier/power.yaml -l 1000
rb power demo_tiny_alu_subsys_sky130_asm_power  -c power/demo_tiny_alu_subsys_hier/power.yaml -l 1000
```

Neither run names a `lib-paths`: since rtl-buddy/rtl_buddy#630 a
`netlist-source: pnr` power run inherits the macro Liberty from the P&R run it
reads, so the SRAM is characterised rather than counted as zero. The
assembly's run also reads both partitions' abstract Liberty through the P&R
run's `blocks:` resolved (rtl-buddy/rtl_buddy#679), but deliberately not
their abstract Liberty (rtl-buddy/rtl_buddy#684): it carries no power tables,
so the partitions count as 0 W either way, and the result names them. A macro
with no library at all is the `power.missing_macro_inputs` ERROR.

## Results — flat vs assembled

Measured with OpenROAD `26Q2-911-g731f8ff5a4`, KLayout 0.30.8 and the released
rtl_buddy 6.70.0 wheel, and re-measured on the 6.77.0 wheel this project now
pins: only the flat column moved (its synthesised netlist is 6 cells smaller,
1217 vs 1223, and setup WNS is +2.95 ns, was +3.08), all from an empty
tree with the one command above, on the PDK revisions `download_pdk.sh` pins,
with `harden: true` on both partitions and the assembly built from `blocks:`.
`apb_clk` 20 ns, `cclk` 25 ns. Every final timing and power number is on
OpenRCX-extracted parasitics (sky130hd sets `rcx-rules`).

These numbers are with wire RC through the whole flow: the sky130hd PDK entry
sets `layer-rc-tcl: pnr/sky130hd/setRC.tcl` and `placement.macro-cell-halo: 3`
(see below). Partitions hardened before this change have stale abstracts and
need re-hardening, which the one command above does.

| | flat | csr partition | compute partition | **assembled** | assembled, RTL-MP |
|---|---|---|---|---|---|
| verdict | PASS | PASS | PASS | **PASS** | PASS |
| standard-cell instances, input / routed | 1217 / 1455 | 376 / 395 | 297 / 305 | **554 / 828** | 554 / 760 |
| die (µm) | 697.5 × 697.5 | 99.3 × 99.3 | 89.6 × 89.6 | **717.2 × 717.2** | 717.2 × 717.2 |
| design area (µm²) | 208 812 | 3 480 | 2 606 | **221 384** | 220 751 |
| core area (µm²) | 456 758 | 7 767 | 6 241 | **483 370** | 483 370 |
| core utilization | 46% | 45% | 42% | **46%** | 46% |
| setup WNS (ns) | +2.95 | +10.75 | +13.47 | **+2.66** | +3.03 |
| setup TNS (ns) | 0.00 | 0.00 | 0.00 | **0.00** | 0.00 |
| hold WNS (ns) | +0.15 | +0.49 | +0.68 | **+0.29** | +0.18 |
| DRC violations | 0 | 0 | 0 | **0** | 0 |
| GDS | `complete` | `complete` | `complete` | **`complete`** | `complete` |
| abstract published | — | yes | yes | — | — |
| static power (mW) | 3.55 | — | — | **4.74** — see below |
| of which the SRAM (mW) | 1.93 | — | — | **1.93** |

Reading it:

- **Worst setup is the same path both ways**: the SRAM's read data out to
  `prdata` — `u_sram` → `prdata[9]` flat, → `prdata[1]` assembled — which no
  partitioning moves. It is 0.29 ns worse assembled. The three macros sit in a
  different place in the assembly's floorplan, and with extracted parasitics
  the longer route from the SRAM to the output pins shows up in full. TNS is
  zero both ways and hold is within 0.15 ns.
- **Design area is +6.0%** assembled: the partitions' own core margin and
  filler are counted at their hardened size rather than as loose cells. **Core
  area is +5.8%**: the assembly uses the flat run's floorplan, and the
  size-aware shelf packer (rtl-buddy/rtl_buddy#632) packs the three macros at
  their real sizes.
- **RTL-MP recovers the setup slack.** `..._asm_rtlmp_pnr` is the same
  assembly with `floorplan.macro-placement: rtl-mp`: OpenROAD's
  `rtl_macro_placer` places the three macros by connectivity, and rotates the
  two partitions (R180 and MY), instead of the packer filling rows from a
  corner. The worst path is still the SRAM-to-`prdata` one, and it gains
  0.37 ns, which puts it 0.08 ns ahead of the flat run. Everything else is unchanged: 0 DRCs, the power grid connected to both
  rotated partitions, strict GDS complete.
- **DRC-clean on every run.** 6.62.0 and 6.63.0 left two met1 spacing
  violations in the assembly, where a standard cell abutted the `u_csr` macro
  edge (rtl-buddy/rtl_buddy#673). 6.64.0 surrounds every macro with a
  standard-cell keep-out, `cfg-pdks.placement.macro-cell-halo` (default
  1 µm). That keep-out also moves the placement and routing a little, which
  accounts for the small shifts in the flat run's timing and area from the
  6.63.0 numbers.
- **Power is not like for like.** The SRAM is 1.93 mW in both. The hardened
  partitions contribute 0 W: `write_timing_model` writes timing arcs and no
  power tables, and the assembly's `rb power` says so, naming both cells as
  having no Liberty power data. So the assembly's total leaves out the
  partitions' own cell power. What it adds is 1.1 mW more switching power on
  the top-level nets (1.58 vs 0.48 mW), which now carry extracted wire
  capacitance between three macros spread over the die, and whose drivers
  inside the partitions switch at OpenSTA's default input activity, since an
  abstract says nothing about them.
- **Wire RC changes repair, not just the final report.** Before
  `layer-rc-tcl`, the sky130hd tech LEF's zero wire RC was all that
  `repair_design`, CTS and hold repair saw (OpenROAD warned EST-0018 and
  CTS-0104), and only the final OpenRCX timing saw real wires. With it,
  `repair_design` buffers the SRAM's long read-data nets (125 buffers on the
  flat run, up from 17), which is where most of the setup gain
  on the SRAM-to-`prdata` path comes from; hold slack shrinks (flat +0.36 →
  +0.15 ns) but stays positive everywhere. Those buffers sat against the SRAM's
  pin edge at the default 1 µm `macro-cell-halo` and overflowed the global
  router's GCell row along it (GRT-0116 on the flat run and the assembly), so
  the sky130hd entry raises the halo to 3 µm.
- **6.64.0 read 3.34 mW here** (rtl-buddy/rtl_buddy#684). It read the
  partitions' abstract Liberty, whose outputs have no `function`, so OpenSTA's
  activity propagation never reached them and every net they drive counted as
  static. 6.65.0 leaves that Liberty out of `rb power`.

## Step-0 spike findings

These are the questions rtl-buddy/rtl_buddy#95 step 0 asks, answered against
this design. They were measured on rtl_buddy 6.56.0, before extracted
parasitics, with the hand-wired abstract flow this example used before
`harden:` existed.

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

One caveat worth recording: the model is extracted with the clocks
propagated through the tree CTS actually built, so the block's own insertion
delay is in the numbers. `harden: true` extracts it in the P&R session after
routing for exactly that reason; extracting under ideal clocks understates the
delay the parent needs.

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

## What is still manual

- **Power of a hardened partition.** `write_timing_model` has no power tables,
  so the partitions are 0 W in the assembly's `rb power` (see the results
  table).

## Files

| file | what it is |
|---|---|
| `synth/demo_tiny_alu_subsys_hier/download_pdk.sh` | fetches sky130hd and the OpenRAM macro into the gitignored `pdk/` |
| `synth/demo_tiny_alu_subsys_hier/synth.yaml` | the four synthesis runs |
| `synth/demo_tiny_alu_subsys_hier/constraints_flat.sdc` | top-level constraints, shared by the flat and assembly runs |
| `synth/demo_tiny_alu_subsys_hier/constraints_csr.sdc` | partition A's single-clock constraints |
| `synth/demo_tiny_alu_subsys_hier/constraints_compute.sdc` | partition B's single-clock constraints |
| `pnr/demo_tiny_alu_subsys_hier/pnr.yaml` | the P&R runs: flat, the multi-corner partition, the two partitions, and the assembly with the packer and with RTL-MP |
| `pnr/sky130hd/pdn.tcl` | top-level power grid, with macro grids |
| `pnr/sky130hd/pdn_block.tcl` | block-level power grid — the convention above |
| `power/demo_tiny_alu_subsys_hier/power.yaml` | post-P&R power for the flat and assembled runs |
| `design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_mem.sv` | technology wrapper — flop array or SRAM macro |
| `design/demo_tiny_alu_subsys/*_bb.sv` | port-only blackboxes for the two partitions and the SRAM |
