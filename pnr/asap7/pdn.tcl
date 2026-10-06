# Power-delivery network for the asap7 platform.
#
# Referenced by `cfg-pdks.asap7.pdn-config` in ../../root_config.yaml. The P&R
# flow sources this file after tap insertion and then calls `pdngen` itself,
# the same contract ORFS uses for its `PDN_TCL` variable — so this file declares
# the grid and never runs the generator.
#
# Copied from OpenROAD-flow-scripts
# flow/platforms/asap7/openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl
# (BSD-3-Clause, The OpenROAD Project) at ORFS commit
# 2aeb23bcc3b5aa925abb991c4347ce73827b8b82, the commit pinned in
# ../../synth/demo_tiny_alu_subsys_asap7/download_pdk.sh (which also fetches
# the upstream file to pdk/asap7/openRoad/pdn/, for comparison).
#
# The grid below is unchanged from upstream: M1/M2 follow-pin rails on the
# 0.54 um ASAP7 row pitch, M5/M6 straps on a 5.4 um pitch, top-level pins on
# M6, and a default macro grid that connects macro M4 pins to the M5 straps.
# It is committed rather than pointed at in pdk/ — unlike the other three
# asap7 hooks — for the same reason ../sky130hd/pdn.tcl is: the power grid is
# project flow configuration that a design team edits (strap pitch, pin layer,
# a block-level variant), not vendor data. It lives under pnr/ so the
# project's `**.tcl` gitignore rule does not catch it.

####################################
# global connections
####################################
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDPE$}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDCE$}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSS$} -ground
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSSE$}
global_connect
####################################
# voltage domains
####################################
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}
####################################
# standard cell grid
####################################
define_pdn_grid -name {top} -voltage_domains {CORE} -pins {M6}
add_pdn_stripe -grid {top} -layer {M1} -width {0.018} -pitch {0.54} -offset {0} -followpins
add_pdn_stripe -grid {top} -layer {M2} -width {0.018} -pitch {0.54} -offset {0} -followpins
add_pdn_stripe -grid {top} -layer {M5} -width {0.12} -spacing {0.072} -pitch {5.4} -offset {0.300}
add_pdn_stripe -grid {top} -layer {M6} -width {0.288} -spacing {0.096} -pitch {5.4} -offset {0.513}
add_pdn_connect -grid {top} -layers {M1 M2}
add_pdn_connect -grid {top} -layers {M2 M5}
add_pdn_connect -grid {top} -layers {M5 M6}
####################################
# macro grids
####################################
####################################
# grid for: CORE_macro_grid_1
####################################
define_pdn_grid -name {CORE_macro_grid_1} -voltage_domains {CORE} -macro \
  -orient {R0 R180 MX MY} -halo {2.0 2.0 2.0 2.0} -default
add_pdn_connect -grid {CORE_macro_grid_1} -layers {M4 M5}
####################################
# grid for: CORE_macro_grid_2
####################################
define_pdn_grid -name {CORE_macro_grid_2} -voltage_domains {CORE} -macro \
  -orient {R90 R270 MXR90 MYR90} -halo {2.0 2.0 2.0 2.0} -default
add_pdn_connect -grid {CORE_macro_grid_2} -layers {M4 M5}
