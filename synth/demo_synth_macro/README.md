# demo_synth_macro

Synthesis of a design that contains a hard macro, and a regression against the
one thing that quietly goes wrong when it does.

## Running it

Tech-independent, no setup:

```sh
rb synth demo_synth_macro_generic -c synth/demo_synth_macro/synth.yaml
```

On sky130hd. Needs the sky130hd views, `openroad`, `yosys` and `klayout` on
PATH. One `rb pnr` builds everything, in order:

```sh
synth/demo_tiny_alu_subsys_hier/download_pdk.sh
rb pnr -c pnr/demo_synth_macro/pnr.yaml --synth -l 1000 --gds
```

That runs four steps. `pnr/demo_synth_macro/pnr.yaml` lists the top first, and
`rb pnr` still hardens the macro before it, because the top names the macro
under `blocks:`. `--synth` runs each P&R run's own synthesis just before it,
so the top is synthesized after the macro's abstract exists:

| step | run | what it produces |
|---|---|---|
| 1 | `rb synth demo_hard_macro_sky130` | the macro's netlist, from `design/demo_synth_macro/demo_hard_macro.sv` |
| 2 | `rb pnr demo_hard_macro_sky130_pnr` | the macro, placed, routed and hardened (`harden: true`): `abstract/demo_hard_macro.{lef,lib,gds}` |
| 3 | `rb synth demo_synth_macro_sky130` | the top's netlist, the macro a blackbox with the abstract as its master |
| 4 | `rb pnr demo_synth_macro_sky130_pnr` | the top, with the macro placed as a hard macro and streamed out from its own GDS |

## What a hard macro needs

Three views, and they come from three different places:

| view | what it is for | where it comes from |
|---|---|---|
| RTL | somewhere for instances to bind | `design/demo_synth_macro/demo_hard_macro_bb.sv`, a port-only `(* blackbox *)` module |
| LEF | placeable extent | the hardened macro's `abstract/demo_hard_macro.lef` |
| Liberty | timing arcs | the hardened macro's `abstract/demo_hard_macro.lib` |

Neither the LEF nor the Liberty is written by hand. `blocks:` on the synth
entry and on the P&R entry resolves `demo_hard_macro` to the abstract its
`harden: true` run published, and fails the run, naming the macro, when there
is none or when the macro's RTL, SDC or configuration changed since it was
hardened. Everything the standard cells need still comes from `platform:`.

The macro's own RTL, `demo_hard_macro.sv`, is compiled only by step 1. The
top's filelist reads the blackbox, so to the top the macro is its abstract and
nothing else, which is what a hard macro is.

## The thing this demo guards

Yosys drops blackbox definitions from `write_verilog`, so the netlist handed to
OpenROAD instantiates `demo_hard_macro` without defining it. `link_design` will
not tolerate an undefined module, so the OpenROAD stage generates a port-only
Verilog stub for each blackbox and reads it.

For a blackbox with no other master that is exactly right. For a macro it is
wrong, because `read_lef` and `read_liberty` have already supplied one. Reading a
Verilog module of the same name as well can lose it, and then every instance
binds to the zero-area Verilog module instead: the macro is gone from the
OpenROAD database, its area is not counted, and its timing arcs are not in the
graph.

Measured on this demo when it still used hand-written Nangate45 views,
changing nothing but which `rtl_buddy` runs it:

| rtl_buddy | reported area | WNS | macro instances after `link_design` |
|---|---|---|---|
| 6.37.0 and earlier | 54 um^2 | +3.906 ns | 0 |
| 6.37.2 onwards | 8054 um^2 | +3.850 ns | 1 |

Fixed in rtl_buddy **6.37.2** (rtl-buddy/rtl_buddy#471), which this project pins.
6.37.1 does **not** have it.

Both runs **PASS**. That is the whole problem: no error, no warning, and a
plausible-looking table. The area is out by 149x, and the WNS is worse than
wrong, it is *optimistic* -- the macro's 0.8 ns `clk` to `q` arc is not in the
graph, so the path it dominates is not being reported at all.

So the stub generator skips any blackbox whose name is already a `MACRO` in one of
the LEFs or a `cell` in one of the Liberty files the same script reads. There is
nothing to configure; this demo exists so the behaviour has a regression.

### Why the bus ports matter

`d` and `q` are 8 bits wide on purpose, and the abstract LEF carries them
bit-blasted (`d[0]` .. `d[7]`), as every generated abstract does.

A version of this macro with only scalar ports does **not** reproduce the bug: the
stub is read and the LEF/Liberty master survives anyway, area and all. Add one
bussed port and the master is lost. The inference is that the Verilog reader can
reconcile an all-scalar module with the master it already has and cannot
reconcile a bussed one; the observation is the load-bearing part, and it means any
macro with a bus, which is every real macro, is exposed.

Keep at least one bussed port here or the demo stops testing anything.

## Checking a run by hand

`artefacts/demo_synth_macro_sky130/synth.tcl` is the direct evidence. It should
read the abstract's LEF and Liberty and the netlist, and contain **no**
`read_verilog` of a generated `or_demo_hard_macro_bb.sv`. There should be no
such file in the artefact directory either.

Then either of these catches a regression on its own:

- **Area includes the macro.** The hardened macro is 67.5 x 67.5 um, about
  4550 um^2, against about 260 um^2 of standard cells around it, so the
  figure is a little over 4800 um^2. A few hundred um^2 means the macro was
  dropped.
- **The macro is in the graph.** Append
  `puts [llength [get_cells -hierarchical *i_macro*]]` to `synth.tcl` and run
  `openroad -no_init -exit` on it. It should print 1.
