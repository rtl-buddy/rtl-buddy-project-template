# demo_tiny_alu_subsys on sky130hd — hierarchical P&R

Hardening two partitions of `demo_tiny_alu_subsys` separately, then placing and
routing the top with those two as hard macros next to a real OpenRAM SRAM.

Each partition's P&R run sets `harden: true`, which publishes its abstract LEF,
Liberty timing model and GDS; the assembly's synthesis and P&R entries name the
two partitions under `blocks:` and take those views from there
(rtl-buddy/rtl_buddy#95). Nothing is wired by hand except the third-party SRAM.

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

The same `pnr.yaml` also holds runs on the flat netlist that show other P&R
features: planner files (step 5), staged runs, repair and probe (step 6), and
the compute partition signed off at three corners on the `sky130hd_mc`
platform (`..._compute_mc_pnr`). The flat design signed off at three corners,
with per-corner SRAM Liberty and signoff gates, is
[`../demo_tiny_alu_subsys_mc/`](../demo_tiny_alu_subsys_mc/README.md).

## What you need

- `openroad` (26Q4), `klayout` and `yosys` on `PATH`.
- The configuration this example relies on, all in
  [`root_config.yaml`](../../root_config.yaml):
  - `cfg-pdks.pdn-config`, `.placement` and `.dont-use-cells` for the sky130hd
    PDK, and a list-valued `cfg-pnr-platforms.cts-buffer`
    (rtl-buddy/rtl_buddy#625);
  - the sky130hd wire RC, `cfg-pdks.layer-rc-tcl` (rtl-buddy/rtl_buddy#716),
    so repair and CTS see real wires;
  - the standard-cell keep-out around macros,
    `cfg-pdks.placement.macro-cell-halo` (rtl-buddy/rtl_buddy#673), which
    keeps the assembly DRC-clean;
  - the row cut around macros, `cfg-pdks.tapcell-tcl`
    ([`../sky130hd/tapcell.tcl`](../sky130hd/tapcell.tcl)), which the
    macro grids' 2 µm halo in `pdn.tcl` needs.
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
synthesis and every P&R below, about seven minutes with `-j 4`. A partition
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

Neither run names a `lib-paths`: a `netlist-source: pnr` power run inherits
the macro Liberty from the P&R run it reads (rtl-buddy/rtl_buddy#630), so the
SRAM is characterised rather than counted as zero. The assembly's run resolves
the partitions through the P&R run's `blocks:` (rtl-buddy/rtl_buddy#679) but
leaves out their abstract Liberty (rtl-buddy/rtl_buddy#684): it carries no
power tables, so the partitions count as 0 W either way, and the result names
them. A macro with no library at all is the `power.missing_macro_inputs`
ERROR.

### 5. Planner files (optional)

A floorplanner, whether a script or a tool, can decide where every macro and
pin goes and write the result as files. `floorplan.macros-file` and
`floorplan.pins-file` read those files as they are, instead of copying hundreds
of entries into `pnr.yaml`. For a handful of hand-chosen entries, write
`floorplan.macros` and `floorplan.pins` inline; when the placement has to be
computed in Tcl, use a [`macro-placement` hook](../../synth/demo_synth_macro/README.md#placing-the-macro-with-a-run-hook).

`demo_tiny_alu_subsys_sky130_planner_pnr` is the flat reference floorplanned
from the two files in `plan/` (rtl-buddy/rtl_buddy#850). It needs the same
synthesis as step 1:

```sh
rb synth demo_tiny_alu_subsys_sky130_flat -c synth/demo_tiny_alu_subsys_hier/synth.yaml
rb pnr   demo_tiny_alu_subsys_sky130_planner_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml \
         -l 1000 --gds
```

| what | where | effect |
|---|---|---|
| macro plan | `plan/macros.yaml`, read by `floorplan.macros-file` | the SRAM rotated 180 degrees (`R180`), its lower-left corner at (80.04, 100.64) µm |
| `macro-snap: false` | `pnr.yaml` | the corner is kept exactly; the default `true` snaps it to the site and row grid |
| pin plan | `plan/pins.yaml`, read by `floorplan.pins-file` | six exact pins, then a side rule for every other port |
| `pin-snap: false` | `pnr.yaml` | each exact pin's centre is kept; the default `true` moves it onto the die edge and a routing track |
| `pins-complete: true` | `pnr.yaml` | the run fails before pin placement if a signal port has no entry, or two |
| `lifetime: global-placement` | the run's `blockages:` | a partial blockage, 35% cell density, that exists only during global placement |

Leave `macro-snap` and `pin-snap` at their defaults when the planner does not
know the site grid or the routing tracks. Set them to `false` when it does and
its numbers are the ones to keep, as here: the SRAM's corner is on the core's
site and row grid, the pins are not on a track.

What to look at, in `pnr/demo_tiny_alu_subsys_hier/artefacts/demo_tiny_alu_subsys_sky130_planner_pnr/`:

- `pnr.log` has `floorplan.macros-file[0]: fixed u_inner/u_hist_mem/u_sram at
  (80.040, 100.640) um R180`, one `placed pin ...` line per exact pin and
  `floorplan.pins-complete: every signal port is covered`. Under
  `>>> Global-placement-only blockages` the screen exists only for
  `global_placement`, and the log says `removed 1 global-placement-only
  blockage(s)` right after it.
- The routed `demo_tiny_alu_subsys_synth_top.def` has the SRAM at
  `FIXED ( 80040 100640 ) S` (DEF's name for R180) and `paddr[0]` at
  `FIXED ( 500 68340 )`.
- `rb pnr` compares the routed DEF with the `RB-FLOORPLAN-MACRO` and
  `RB-FLOORPLAN-PIN` lines the log recorded, after OpenROAD exits. A macro at
  another location or orientation, or a pin on another layer or box, fails the
  run with `fail_stage: routed_check`. This run passes it.

Remove `pwrite` and `crst_n` from the last rule of `plan/pins.yaml` and the run
fails before it places any pin, with
`floorplan.pins-complete: 2 port(s) matched by no entry (crst_n, pwrite)`.

The SRAM is rotated 180 degrees, not 90, so that the PDK's macro grid in
`pnr/sky130hd/pdn.tcl` powers it: `R0`, `R180`, `MX` and `MY` keep its supply
sides vertical. A 90-degree turn (`R90`, `R270`, `MXR90`, `MYR90`) needs a PDN
macro grid that reaches the turned power pins, and the shipped sky130hd grid
cannot do this for the OpenRAM SRAM
([#143](https://github.com/rtl-buddy/rtl-buddy-project-template/issues/143)).
To check the supply, read the routed `.odb` back into OpenROAD and run
`check_power_grid -net VDD` and `-net VSS`.

### 6. Staged runs and timing repair (optional)

Three more runs on the flat reference, showing staged runs, repair and probe
(rtl-buddy/rtl_buddy#848, #849) and timing-driven placement (#867). They need
the same synthesis as step 1. Post-route repair also needs the PDK's
`rcx-rules`, which the sky130hd entry sets.

```sh
rb synth demo_tiny_alu_subsys_sky130_flat -c synth/demo_tiny_alu_subsys_hier/synth.yaml
rb pnr   demo_tiny_alu_subsys_sky130_tight_pnr  -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000
rb pnr   demo_tiny_alu_subsys_sky130_repair_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000
rb pnr   demo_tiny_alu_subsys_sky130_probe_pnr  -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000
```

`..._tight_pnr` and `..._repair_pnr` run the flat reference with `apb_clk` at
12.6 ns (`constraints_flat_tight.sdc`) instead of 20 ns. The worst setup path is
the SRAM's read data out to `prdata`, launched on the falling clock edge, so at
12.6 ns it keeps negative slack through the flow's default timing repair. Both
run the same synthesised netlist and the same floorplan.

| what | where | effect |
|---|---|---|
| `placement.timing-driven: true` | both runs | `global_placement -timing_driven`: the placer weights the nets on the worst setup paths. On OpenROAD 26Q4 it also buffers and resizes cells during placement |
| `stages: true` | `..._repair_pnr` | each stage (`floorplan`, `place`, `cts`, `global_route`, `detailed_route`, `post_route_repair`, `finish`) is its own OpenROAD session and writes a checkpoint |
| `global-route-repair` | `..._repair_pnr` | after global route, `repair_design` with a 20% slew and capacitance margin. A written block runs only what it sets, so this run leaves out the setup and hold repair that the default block, which `..._tight_pnr` runs, adds there |
| `post-route-repair` | `..._repair_pnr` | up to two rounds that extract the routed design and, while setup slack is negative, run `repair_timing -setup` with a 0.05 ns margin (0.10 ns in round 2), then route the changed nets again and keep every other wire (`reroute: eco`) |
| `resources` | `..._repair_pnr` | the Slurm reservation of each stage job under `--dispatch slurm`; ignored otherwise |
| `mode: probe` | `..._probe_pnr` | placement and global route only, at 70% utilization instead of 45%; no timing repair, no routed design |

A round starts only when setup slack is negative: `setup-margin` sets how much
slack the repair aims for, not when it runs. On a design that already meets
timing the stage runs its extraction and stops.

| | tight | repair |
|---|---|---|
| verdict | PASS | PASS |
| routed cells | 1 455 | 1 469 |
| design area (µm²) | 209 508 | 209 656 |
| setup WNS (ns) | **-0.12** | **-0.06** |
| setup TNS (ns) | -0.15 | -0.10 |
| hold WNS (ns) | +0.30 | +0.29 |
| DRC violations | 0 | 0 |
| max-slew / max-cap violators | 11 / 1 | 9 / 1 |

Measured with OpenROAD 26Q4 on a shared host, from the synthesis above, with
`threads:` unset. Runs of the same configuration on the same host gave the
same numbers. Each run takes a few minutes.

Reading it:

- **A `PASS` is not timing met.** `..._tight_pnr` passes with -0.12 ns of
  setup slack and a TNS of -0.15 ns; `wns_setup_ps` and `tns_ps` are the
  verdict, as for every `rb pnr` run.
- **Post-route repair recovers most of the setup slack.** After detailed route
  the worst setup slack, on the SRAM read path, is -0.29 ns (TNS -0.81 ns).
  Round 1 repairs it to -0.09 ns, round 2, with the margin raised to 0.10 ns,
  to -0.06 ns (TNS -0.10 ns), and the final report is on the extracted
  parasitics of that route. Neither run closes at 12.6 ns. `progress.jsonl` in
  `artefacts/<run>/checkpoints/latest/` has a `post_route_round` event per
  round, and `pnr.log` has each round's `worst slack max` under
  `>>> Post-route repair timing, round N`. The two runs' routes differ from
  global route on, since their global-route repairs differ, so the repair
  run's starting point is not the tight run's result: its global-route repair
  leaves setup to the post-route rounds.
- **Global-route repair** runs in both. The tight run's default block repairs
  setup and hold there as well as slew and capacitance, which is why it
  reaches the end of detailed route with less negative slack than the repair
  run.
- **Each repair is logged where it runs.** `pnr.log` announces
  `>>> Global-route repair: repair_design -slew_margin 20 -cap_margin 20` and
  `>>> Post-route repair round 1 of 2: repair on extracted parasitics (reroute eco)`.
  A round that makes slack worse is still kept when it is the last one that
  repaired, so compare the rounds' slack in `progress.jsonl` before trusting
  the result, and raise `rounds` or the margins when the stage stops short.
- **Probe.** `..._probe_pnr` finishes in seconds with `routed: false`,
  `mode: probe`, `stopped_after: global_route` and `global_route_overflow: 0`:
  the denser floorplan places and routes globally. It says nothing about
  detailed route or timing after repair; it is a screen before a closure run.

#### Stop after a stage, resume from a checkpoint

```sh
rb pnr demo_tiny_alu_subsys_sky130_repair_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000 \
       --stop-after global_route
rb pnr demo_tiny_alu_subsys_sky130_repair_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000 \
       --resume latest --from detailed_route
```

The first command ends once the `global_route` checkpoint is written, in about
10 seconds. The result is a `PASS` with `routed: false` and
`stopped_after: global_route`, with the timing on the global-route estimate
(setup WNS -0.20 ns) and the overflow, and no routed DEF, ODB or SPEF.

The second starts a new run directory at `detailed_route` from that
checkpoint: it routes in detail, runs both repair rounds and finishes. Its
result is the full run's, number for number, and its `manifest.json` records
`resumed_from` with the run id and stage. `--resume` takes `latest`, a run id
under `artefacts/<run>/checkpoints/` or a checkpoint directory; the run it
reads is left as it was, so the same global route can be resumed again, by its
run id, with other detailed-route settings. A resume is refused, naming what differs, when
the scripts of the stages it would skip, an input file or the OpenROAD version
changed since the checkpoint was written.

Only the stages from `--from` on read their settings again, so repair alone can
be retried without placing or routing again. Change `post-route-repair` in
`pnr.yaml` (`rounds`, `setup-margin`, `margin-step`), then:

```sh
rb pnr demo_tiny_alu_subsys_sky130_repair_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000 \
       --resume latest --from post_route_repair
```

#### Dispatch the stages to Slurm

```sh
rb pnr demo_tiny_alu_subsys_sky130_repair_pnr -c pnr/demo_tiny_alu_subsys_hier/pnr.yaml -l 1000 \
       --dispatch slurm
```

rb writes every stage's script into the run directory, then submits one Slurm
job per stage, each held until the one before it succeeds, named
`rb:pnr:<run>:<stage>`, and waits until the last has left the queue. Each job
reserves what `resources:` gives its stage: `..._repair_pnr` asks for 4G and 30
minutes, and for 8G and an hour in `detailed_route` and `post_route_repair`.
With `threads:` unset OpenROAD picks its own thread count in each job;
`threads: auto` takes the job's CPUs, though results are not guaranteed
identical across thread counts. The result,
manifest and outputs are those of the same run staged locally, and each job's
script, log and result are under `checkpoints/<run id>/dispatch/`.
`--dispatch slurm` combines with `--stop-after` and `--resume`: only the stages
the run executes are submitted.

The template's CI has no Slurm and runs none of these P&R runs; this command
needs a host with `sbatch`.

## Results — flat vs assembled

Measured with OpenROAD 26Q4 and KLayout 0.30, from an empty tree with the one
command above, on the PDK revisions `download_pdk.sh` pins, with `threads:`
unset. `apb_clk` 20 ns, `cclk` 25 ns. Every final timing and power
number is on OpenRCX-extracted parasitics (sky130hd sets `rcx-rules`).

| | flat | csr partition | compute partition | **assembled** | assembled, RTL-MP |
|---|---|---|---|---|---|
| verdict | PASS | PASS | PASS | **PASS** | PASS |
| standard-cell instances, input / routed | 1217 / 1493 | 376 / 561 | 297 / 362 | **554 / 961** | 554 / 782 |
| die (µm) | 697.5 × 697.5 | 99.3 × 99.3 | 89.6 × 89.6 | **717.2 × 717.2** | 717.2 × 717.2 |
| design area (µm²) | 209 823 | 4 720 | 3 073 | **222 693** | 221 683 |
| core area (µm²) | 456 758 | 7 767 | 6 241 | **483 370** | 483 370 |
| core utilization | 46% | 61% | 49% | **46%** | 46% |
| setup WNS (ns) | +3.35 | +10.80 | +13.57 | **+3.06** | +3.45 |
| setup TNS (ns) | 0.00 | 0.00 | 0.00 | **0.00** | 0.00 |
| hold WNS (ns) | +0.35 | +0.47 | +0.66 | **+0.32** | +0.16 |
| DRC violations | 0 | 0 | 0 | **0** | 0 |
| max-slew / max-cap violators | 8 / 2 | 0 / 0 | 0 / 0 | **29 / 6** | 8 / 0 |
| GDS | `complete` | `complete` | `complete` | **`complete`** | `complete` |
| abstract published | — | yes | yes | — | — |
| port buffers, in / out | — | 85 / 78 | 42 / 15 | — | — |
| largest abstract input pin cap (pF) | — | 0.016 | 0.012 | — | — |
| static power (mW) | 3.90 | — | — | **5.14** — see below | — |
| of which the SRAM (mW) | 1.93 | — | — | **1.93** | — |

Reading it:

- **Worst setup is the same path both ways**: the SRAM's read data out to
  `prdata`, which no partitioning moves. It is 0.29 ns worse assembled: the
  three macros sit in a different place in the assembly's floorplan, and with
  extracted parasitics the longer route from the SRAM to the output pins shows
  up in full. TNS is zero both ways and hold is within 0.1 ns.
- **Design area is +6.1%** assembled: the partitions' own core margin and
  filler are counted at their hardened size rather than as loose cells. **Core
  area is +5.8%**: the assembly uses the flat run's floorplan, and the
  size-aware shelf packer (rtl-buddy/rtl_buddy#632) packs the three macros at
  their real sizes, with `placement.macro-halo` (20 µm by default) of clearance
  around each for the PDN channels.
- **RTL-MP recovers the setup slack.** `..._asm_rtlmp_pnr` is the same
  assembly with `floorplan.macro-placement: rtl-mp`: OpenROAD's
  `rtl_macro_placer` places the three macros by connectivity, and turns the
  compute partition and the SRAM 180 degrees, instead of the packer filling
  rows from a corner. The worst path is still the SRAM-to-`prdata` one, and it gains 0.39 ns, which puts it
  0.10 ns ahead of the flat run. 0 DRCs, the power grid connected to the
  rotated macros, strict GDS complete.
- **DRC-clean on every run.** `cfg-pdks.placement.macro-cell-halo` keeps
  standard cells off every macro edge. The sky130hd entry sets it to 3 µm:
  `repair_design` buffers the SRAM's long read-data nets, and at 1 µm those
  buffers sit against the SRAM's pin edge and overflow the global router's
  GCell row along it (GRT-0116).
- **Power is not like for like.** The SRAM is 1.93 mW in both. The hardened
  partitions contribute 0 W: `write_timing_model` writes timing arcs and no
  power tables, and the assembly's `rb power` says so, naming both cells as
  having no Liberty power data. So the assembly's total leaves out the
  partitions' own cell power. What it adds is about 1.1 mW more switching power
  on the top-level nets (1.63 vs 0.51 mW), which carry extracted wire
  capacitance between three macros spread over the die, and whose drivers
  inside the partitions switch at OpenSTA's default input activity, since an
  abstract says nothing about them. `rb power` leaves the partitions' abstract
  Liberty out (rtl-buddy/rtl_buddy#684): its outputs have no `function`, so
  activity propagation would stop at them.
- **Wire RC drives repair, not just the final report.** `layer-rc-tcl` gives
  `repair_design`, CTS and hold repair the sky130hd wire RC, which the tech LEF
  lacks; without it OpenROAD warns EST-0018 and CTS-0104 and only the final
  OpenRCX timing sees real wires. With it, `repair_design` buffers the SRAM's
  long read-data nets, which is where most of the setup slack on the
  SRAM-to-`prdata` path comes from.
- **Hardened partitions have buffered ports.** `harden: true` runs
  `buffer_ports` before global placement, with the cell `sky130hd_tt_block`
  names in `port-buffer` (`sky130_fd_sc_hd__buf_4`): 163 buffers on csr, 57 on
  compute. Each abstract then presents one buffer's input capacitance to the
  parent rather than its internal fanout. Without `port-buffer`, OpenROAD picks
  the delay cell `clkdlybuf4s50_1` and csr loses about 0.9 ns of setup.
- **Electrical violators are counted.** Every run reports its max-slew and
  max-capacitance violators; the flat run and both assemblies have some,
  mostly at the SRAM: its `dout1` pins have a 0.03 pF max-capacitance limit
  their read-data nets exceed, and its address pins a 0.04 ns max-slew limit.
  The packer assembly also has top-level nets past the 1.5 ns slew limit. They
  pass with an "electrical" note. The counts vary
  a little between identical runs. `fail-on-electrical: true` on a run, or
  `electrical` in its `signoff.fail-on`, makes them fail it.
- **Supply connections.** `rb pnr` applies the PDK's global connections again
  at the end of every stage, so the buffers, CTS cells and fill added after
  `pdngen` have their supply pins connected in the routed database.
  `<top>.routed.v` is the logical netlist, with no supply ports;
  `<top>.routed.pwr.v` is the powered one, for LVS. A hardened block's
  abstract Liberty lists `VDD` and `VSS` as `input` pins.

## Design notes

### `write_timing_model` abstracts load cleanly

- **Yosys** — `synth.ys` reads each abstract with `read_liberty -lib` and the
  log says `Imported 1 cell types from liberty file` for each, with nothing
  else. rtl_buddy also hands each abstract to a `dfflibmap` pass; those passes
  find no sequential cells to map and are silent. ABC is given only the
  platform Liberty, so a macro is never a mapping target.
- **OpenROAD / OpenSTA at the top** — the abstracts load and produce real
  boundary arcs. `report_checks -to [get_pins u_inner/u_csr/*]` ends paths on
  the macro's input pins against the abstract's setup checks, and
  `report_checks -from [get_pins u_inner/u_compute/*]` starts paths at its
  output pins with clock-to-out delay. There are no `STA-` warnings about
  missing arcs or unconstrained pins on either block.

The model is extracted with the clocks propagated through the tree CTS built,
so the block's own insertion delay is in the numbers. `harden: true` extracts
it in the P&R session after routing for that reason; extracting under ideal
clocks would understate the delay the parent needs.

To compare a boundary path between the flat run and the assembly, read the
run's `*.routed.odb` and `*.routed.sdc` back into OpenROAD with the
`read_liberty` lines from its own `pnr.tcl`, then `set_propagated_clock
[all_clocks]` and `read_spef` the run's `*.routed.spef` before `report_checks`.

### The abstract LEF power pins connect to the top PDN

`check_power_grid` reports `[INFO PSM-0040] All shapes on net VDD are
connected` and the same for VSS, on the assembly and on the flat and
partition runs. That depends on the block-level PDN convention.

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

A block grid that exposes on met5, as ORFS' sky130hd `pdn.tcl` does, makes
the assembly fail:

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

With the block grid on met5, the CSR abstract's `OBS` section lists
`li1 met1 met2 met3 met4 met5` and its VDD/VSS pins are met5 horizontals.
With the block grid stopped at met4, the same abstract's `OBS` lists
`li1 met1 met2 met3 met4` — no met5 — and its VDD/VSS pins are met4 verticals.

It is also what the third-party macro does. The OpenRAM SRAM exposes
`vccd1` / `vssd1` on met4 and met3. A hardened partition that does the same is
indistinguishable from it at the top, which is the property the whole flow
depends on.

#### Rows around macros

The top-level grid's macro grids in `pnr/sky130hd/pdn.tcl` keep a 2 µm halo
around each macro, which keeps strap ends and via stacks clear of the macro's
pin edges. `pdngen` fails a halo that reaches a standard-cell row the macro
does not sit on (`PDN-0008`), so `pnr/sky130hd/tapcell.tcl`, the PDK's
`tapcell-tcl`, cuts the rows 2 µm around every macro first, as ORFS' tapcell
step does.

### The SRAM is in the assembled GDS

`def2stream.report.json` says `"complete": true` with `"missing_cells": []`
and `"allowed_empty_cells": []`, and the layout carries all three macros:
the SRAM, `demo_tiny_alu_subsys_csr` and `demo_tiny_alu_subsys_compute`, each
streamed from its own GDS.

### The interface port at the synthesis top

Yosys' `read_verilog` warns about `apb_intf` at
`demo_tiny_alu_subsys_synth_top` on the flat and assembly synthesis:

```text
Warning: Could not find interface instance for `bus' in `demo_tiny_alu_subsys_synth_top'
Warning: Range select [5:0] out of bounds on signal `\apb.paddr': Setting all 6 result bits to undef.
```

rtl_buddy classifies that warning through the `unresolved-interfaces` synth
gate (`cfg-synth-tools`, `error` / `warn` / `allow`, default `warn`,
rtl-buddy/rtl_buddy#629), once per unbound instance:

```text
WARNING  interface instance demo_tiny_alu_subsys_synth_top.bus could not be
         bound to the interface port it is passed to; its own port connections
         are dropped from the netlist, leaving any clock or reset it carries
         undriven. frontend: slang binds it correctly
```

The warning is **benign on this design** — the netlist is connected. The
out-of-bounds select comes from a throwaway elaboration made before the
interface port is derived; the derived module carries the full-width `paddr`
and the correct slice into the CSR block, and the design is formally
equivalent at its outputs to a `read_slang` elaboration of the same sources.
The only undriven nets are `apb_intf`'s own `clk` / `rst_n` ports, which this
subsystem never reads (it clocks off `apb_clk` / `apb_rst_n`).

The general hazard behind the warning is real: `read_verilog` drops an
interface *instance's* own port connections, so a design that does read
`bus.clk` would synthesize clockless. A project whose design reads through an
interface instance should set `unresolved-interfaces: error`, or move that run
to `frontend: slang`, which binds it correctly (rtl-buddy/rtl_buddy#628).
`lint/cdc/cdc.yaml` puts `demo_tiny_alu_subsys_lint` on the pyslang frontend
for the same reason.

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
| `pnr/demo_tiny_alu_subsys_hier/pnr.yaml` | the P&R runs: flat, the multi-corner partition, the two partitions, the assembly with the packer and with RTL-MP, the flat run floorplanned from planner files, and the flat run at a tight clock without and with staged repair, plus a probe of a denser floorplan |
| `pnr/demo_tiny_alu_subsys_hier/constraints_flat_tight.sdc` | the flat constraints with `apb_clk` at 12.6 ns, read by the tight and repair runs |
| `pnr/demo_tiny_alu_subsys_hier/plan/macros.yaml` | the macro plan the planner-files run reads: the SRAM, rotated 180 degrees, at an explicit location |
| `pnr/demo_tiny_alu_subsys_hier/plan/pins.yaml` | the pin plan it reads: six exact pins and a side rule for every other port |
| `pnr/sky130hd/pdn.tcl` | top-level power grid, with macro grids |
| `pnr/sky130hd/pdn_block.tcl` | block-level power grid — the convention above |
| `pnr/sky130hd/tapcell.tcl` | cuts the standard-cell rows 2 µm around each macro, as far as the macro grids' halo reaches |
| `power/demo_tiny_alu_subsys_hier/power.yaml` | post-P&R power for the flat and assembled runs |
| `design/demo_tiny_alu_subsys/demo_tiny_alu_subsys_mem.sv` | technology wrapper — flop array or SRAM macro |
| `design/demo_tiny_alu_subsys/*_bb.sv` | port-only blackboxes for the two partitions and the SRAM |
