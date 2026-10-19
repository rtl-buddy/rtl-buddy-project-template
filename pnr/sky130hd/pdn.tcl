# Power-delivery network for the sky130hd platform.
#
# Referenced by `cfg-pdks.sky130hd.pdn-config` in ../../root_config.yaml. The
# P&R flow sources this file after macro placement and then calls `pdngen`
# itself, the same contract ORFS uses for its `PDN_TCL` variable — so this file
# declares the grid and never runs the generator.
#
# Adapted from OpenROAD-flow-scripts flow/platforms/sky130hd/pdn.tcl
# (BSD-3-Clause, The OpenROAD Project), at the commit pinned in
# ../../synth/demo_tiny_alu_subsys_hier/download_pdk.sh. Three changes from the
# upstream file, all noted where they appear:
#
#   1. Global connections for the OpenRAM macros' vccd1 / vssd1 power pins,
#      which upstream does not carry because its default platform has no
#      memories.
#   2. Comments explaining what the hierarchical flow depends on, since this
#      file is the block-level PDN convention that
#      ../demo_tiny_alu_subsys_hier/README.md documents.
#   3. No macro-grid halo above or below a macro, because the rtl_buddy flow
#      does not cut the standard-cell rows around a macro as ORFS does.
#
# Nangate45 does not use this file: its `cfg-pdks` entry declares no
# `pdn-config`, so no `pdngen` block is emitted and its flow is unchanged.

####################################
# global connections
####################################
# Standard cells: sky130 names its cell rails VPWR / VGND and its well taps
# VPB / VNB.
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDPE$}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDCE$}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VPWR}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VPB}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSS$} -ground
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSSE$}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VGND}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VNB}

# OpenRAM macros. Their LEF exposes the supply as vccd1 / vssd1 (the Caravel
# user-area net names), which match none of the patterns above — without these
# two lines the SRAM's power pins are left floating and `pdngen` builds a grid
# that reaches every standard cell and no memory.
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^vccd1$} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^vssd1$} -ground

global_connect

####################################
# voltage domains
####################################
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

####################################
# standard cell grid
####################################
# met1 followpins carry the cell rails; met4/met5 are the coarse straps, and
# met5 is the layer the grid is exposed on. A hardened block built with this
# same file therefore owns met1 through met5 internally and presents its supply
# on met5 — which is what lets the top-level grid land on it, since the top's
# own straps are on met4/met5 too.
define_pdn_grid -name {grid} -voltage_domains {CORE} -pins {met5}
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {5.44} -offset {0} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.600} -pitch {27.140} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.600} -pitch {27.200} -offset {13.600}
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}

####################################
# macro grids
####################################
# Two grids, one per orientation family, because a macro's power pins rotate
# with it. `-grid_over_boundary` lets the top-level met4/met5 straps run across
# the macro and drop vias onto its pins, which is how a hard macro — an OpenRAM
# SRAM or a hardened partition — is tied into the top-level supply.
#
# The halo keeps the standard-cell grid's followpins and via stacks that far
# off the macro, on top of the minimum spacing pdngen always keeps. It may not
# reach a row the macro does not sit on: the grid lays no followpin inside a
# halo, so pdngen fails such a halo with PDN-0008. ORFS cuts the rows 2 um
# around each macro before it builds the grid, so its 2 um halo on every side
# lands on no row. The rtl_buddy flow leaves the rows whole and keeps cells
# off a macro with a placement blockage instead (`placement.macro-cell-halo`
# in ../../root_config.yaml), and the macro packer puts a macro's bottom edge
# on a row boundary, so any halo above or below a macro reaches the
# neighbouring row. The halo here is 2 um to the left and right only, over
# rows the macro itself sits on.
#
# `-halo` is {left bottom right top} in the macro's own frame and turns with
# the macro, which is why the quarter-turn grid writes it as {0 2 0 2}.
#
# This is the half of the hierarchical convention that lives at the top. The
# other half is the block-level grid above: a block hardened for consumption
# here must expose its supply on met5, and must not route signals on met5 in a
# way that would collide with the parent's straps.
####################################
# grid for: CORE_macro_grid_1
####################################
define_pdn_grid -name {CORE_macro_grid_1} -voltage_domains {CORE} -macro \
  -orient {R0 R180 MX MY} -halo {2.0 0.0 2.0 0.0} -default -grid_over_boundary
add_pdn_connect -grid {CORE_macro_grid_1} -layers {met4 met5}
####################################
# grid for: CORE_macro_grid_2
####################################
define_pdn_grid -name {CORE_macro_grid_2} -voltage_domains {CORE} -macro \
  -orient {R90 R270 MXR90 MYR90} -halo {0.0 2.0 0.0 2.0} -default -grid_over_boundary
add_pdn_connect -grid {CORE_macro_grid_2} -layers {met4 met5}
