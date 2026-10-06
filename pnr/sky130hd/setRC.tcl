# Per-layer wire RC for the sky130hd platform.
#
# Referenced by `cfg-pdks.sky130hd.layer-rc-tcl` in ../../root_config.yaml
# (and inherited by `sky130hd_block`). The P&R flow sources it after
# `read_sdc`, the step where ORFS sources its SET_RC_TCL, so `repair_design`,
# CTS, hold repair and the final reports all see wire resistance and
# capacitance. `rb power` with `netlist-source: pnr` sources it too.
#
# Without it the sky130hd tech LEF's RC is all the flow has, and that is zero:
# OpenROAD warns EST-0018 / CTS-0104, CTS balances a tree with no wire delay,
# and hold repair runs against an estimate that the OpenRCX extraction at the
# end of the flow (`rcx-rules`) then contradicts — a latent hold escape that
# only the final, extracted timing shows.
#
# The `set_layer_rc` lines are OpenROAD test/sky130hd/sky130hd.rc
# (BSD-3-Clause, The OpenROAD Project) at OpenROAD commit
# 731f8ff5a4804791a895fe594e482136fb2101bb, the commit
# ../../synth/demo_tiny_alu_subsys_hier/download_pdk.sh pins for the ss / ff
# Liberty, unchanged. The two `set_wire_rc` lines are added, with the layers
# the same commit's test/sky130hd/sky130hd.vars names for the default signal
# and clock wire RC (`wire_rc_layer met2`, `wire_rc_layer_clk met5`).
#
# ORFS ships its own flow/platforms/sky130hd/setRC.tcl, with slightly higher
# met1-met5 resistance and met1 / met3 as the wire RC layers. This file
# follows the OpenROAD test views because the ss / ff Liberty already come
# from there.

# correlateRC.py gcd,ibex,aes,jpeg,chameleon,riscv32i,chameleon_hier
# cap units pf/um
set_layer_rc -layer li1 -capacitance 1.499e-04 -resistance 7.176e-02
set_layer_rc -layer met1 -capacitance 1.72375E-04 -resistance 8.929e-04
set_layer_rc -layer met2 -capacitance 1.36233E-04 -resistance 8.929e-04
set_layer_rc -layer met3 -capacitance 2.14962E-04 -resistance 1.567e-04
set_layer_rc -layer met4 -capacitance 1.48128E-04 -resistance 1.567e-04
set_layer_rc -layer met5 -capacitance 1.54087E-04 -resistance 1.781e-05
# end correlate

set_layer_rc -via mcon -resistance 9.249146E-3
set_layer_rc -via via -resistance 4.5E-3
set_layer_rc -via via2 -resistance 3.368786E-3
set_layer_rc -via via3 -resistance 0.376635E-3
set_layer_rc -via via4 -resistance 0.00580E-3

# Default wire RC for estimates before routing (OpenROAD sky130hd.vars:
# signal on met2, clock on met5).
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5
