# Per-layer wire RC for the nangate45 platform.
#
# Referenced by `cfg-pdks.nangate45.layer-rc-tcl` in ../../root_config.yaml.
# The P&R flow sources it after `read_sdc`, the step where ORFS sources its
# SET_RC_TCL, so setup and hold repair, CTS and the final reports see wire
# resistance and capacitance. `rb power` with `netlist-source: pnr` sources it
# too. The Nangate45 tech LEF has no wire RC, so without this file every setup
# repair in the flow stops with RSZ-0089.
#
# The lines below are OpenROAD-flow-scripts flow/platforms/nangate45/setRC.tcl
# at ORFS commit 7bf5a814e47c54ec6c64692b464d398184d99891, unchanged. That
# platform directory is licensed under the Apache License 2.0
# (flow/platforms/nangate45/LICENSE in ORFS,
# https://www.apache.org/licenses/LICENSE-2.0).

set_layer_rc -layer metal1 -resistance 5.4286e-03 -capacitance 7.41819E-02
set_layer_rc -layer metal2 -resistance 3.57167E-03 -capacitance 8.33611E-02
set_layer_rc -layer metal3 -resistance 3.57147E-03 -capacitance 1.03981E-01
set_layer_rc -layer metal4 -resistance 1.50001E-03 -capacitance 1.19150E-01
set_layer_rc -layer metal5 -resistance 1.50000E-03 -capacitance 1.09256E-01
set_layer_rc -layer metal6 -resistance 1.50000E-03 -capacitance 1.14168E-01
set_layer_rc -layer metal7 -resistance 1.87501E-04 -capacitance 1.17491E-01
set_layer_rc -layer metal8 -resistance 1.87501E-04 -capacitance 9.45346E-02
set_layer_rc -layer metal9 -resistance 3.74996E-05 -capacitance 1.06091E-01
set_layer_rc -layer metal10 -resistance 3.75000E-05 -capacitance 7.37095E-01

set_wire_rc -signal -layer metal3
set_wire_rc -clock -layer metal5
