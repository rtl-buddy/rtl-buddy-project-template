# demo_synth_macro

A design with a hard macro in it: `demo_hard_macro`, a blackbox in the top's RTL
and a real master to the backend.

    demo_hard_macro_bb.sv      port-only (* blackbox *) declaration, what the top reads
    demo_hard_macro.sv         the macro's RTL, what it is hardened from
    demo_synth_macro_top.sv    the macro plus a short standard-cell pipeline

The macro's physical and timing views are not in this directory. They are
generated: `pnr/demo_synth_macro/pnr.yaml` hardens `demo_hard_macro.sv` on
sky130hd with `harden: true`, which publishes its abstract LEF, Liberty timing
model and GDS, and the top's synthesis and P&R take them from there through
`blocks:`. It stands in for a compiled SRAM or any vendor block, and for a
partition of your own design hardened once and reused.

See `synth/demo_synth_macro/README.md` for what the flow does with it.
