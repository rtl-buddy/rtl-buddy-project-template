# demo_synth_macro

A design with a hard macro in it: `demo_hard_macro`, a blackbox in RTL and a real
master to the backend.

    demo_hard_macro_bb.sv      port-only (* blackbox *) declaration
    demo_synth_macro_top.sv    the macro plus a short standard-cell pipeline
    macro/demo_hard_macro.lef  physical extent (CLASS BLOCK, 100 x 80 um)
    macro/demo_hard_macro.lib  timing arcs, area 8000

The macro is synthetic and hand-written, so nothing here needs a vendor download.
It stands in for a compiled SRAM or any vendor block: 8000 um^2 against a handful
of standard cells, so an area figure that omits it is obvious rather than merely
wrong.

The views are carried here rather than under `pdk/` on purpose. A PDK is per
process; a hard macro is per design, which is why `synth.yaml` names it with
`lef-paths` / `lib-paths` instead of `platform`.

See `synth/demo_synth_macro/README.md` for what the flow does with it.
