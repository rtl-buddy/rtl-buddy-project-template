# demo_synth_macro

Synthesis of a design that contains a hard macro, and a regression against the
one thing that quietly goes wrong when it does.

## Running it

Tech-independent, no setup:

```sh
rb synth demo_synth_macro_generic -c synth/demo_synth_macro/synth.yaml
```

Tech-mapped through OpenROAD. Needs the Nangate45 views and `openroad` on PATH:

```sh
synth/demo_tiny_alu_subsys/download_pdk.sh
rb synth demo_synth_macro_nangate45 -c synth/demo_synth_macro/synth.yaml
```

## What a hard macro needs

Three views, and they come from three different places:

| view | what it is for | where it comes from |
|---|---|---|
| RTL | somewhere for instances to bind | `design/demo_synth_macro/demo_hard_macro_bb.sv`, a port-only `(* blackbox *)` module |
| LEF | placeable extent | `lef-paths` on the synth entry |
| Liberty | timing arcs | `lib-paths` on the synth entry |

`lef-paths` and `lib-paths` sit on the synth entry rather than in
`root_config.yaml`'s `cfg-pdks` because a PDK is per process and a macro is per
design. Everything the standard cells need still comes from `platform:`.

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

Measured on this demo, changing nothing but which `rtl_buddy` runs it:

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

`d` and `q` are 8 bits wide on purpose, and the LEF carries them bit-blasted
(`d[0]` .. `d[7]`) the way a compiled macro's abstract does.

A version of this macro with only scalar ports does **not** reproduce the bug: the
stub is read and the LEF/Liberty master survives anyway, area and all. Add one
bussed port and the master is lost. The inference is that the Verilog reader can
reconcile an all-scalar module with the master it already has and cannot
reconcile a bussed one; the observation is the load-bearing part, and it means any
macro with a bus, which is every real macro, is exposed.

Keep at least one bussed port here or the demo stops testing anything.

## Checking a run by hand

`artefacts/demo_synth_macro_nangate45/synth.tcl` is the direct evidence. It should
read the macro LEF and Liberty and the netlist, and contain **no** `read_verilog`
of a generated `or_demo_hard_macro_bb.sv`. There should be no such file in the
artefact directory either.

Then either of these catches a regression on its own:

- **Area includes the macro.** `demo_hard_macro` is `area : 8000` against about
  54 um^2 of standard cells, so the figure is a little over 8000. Tens of um^2
  means the macro was dropped.
- **The macro is in the graph.** Append
  `puts [llength [get_cells -hierarchical *i_macro*]]` to `synth.tcl` and run
  `openroad -no_init -exit` on it. It should print 1.
