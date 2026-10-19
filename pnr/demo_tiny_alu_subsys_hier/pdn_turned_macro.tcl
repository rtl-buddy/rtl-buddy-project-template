# Power-delivery network for the planner-files run in pnr.yaml.
#
# A copy of ../sky130hd/pdn.tcl, the PDK's pdn-config, without its macro grid
# for turned orientations (R90 R270 MXR90 MYR90). The run's `pdn-config` replaces
# the PDK's, so the other runs keep the full file.
#
# Why the turned grid is left out: the OpenRAM SRAM's supply ring is met4
# verticals joined by met3 horizontals, and the PDK grid reaches it by dropping
# met4-met5 vias where the core's horizontal met5 straps cross the vertical met4
# sides. Turned by 90 degrees the met4 sides run horizontally, parallel to the
# straps, so no via lands, the macro grid gets no shapes and `pdngen` stops with
# PDN-0233. With no grid for the turned orientation `pdngen` completes, and
# the SRAM's vccd1 / vssd1 pins stay unconnected: `check_power_grid` on the
# routed result reports PSM-0039 for them. This run checks macro and pin
# placement, not the SRAM's supply. A design that turns a macro needs a supply
# scheme for the turned pins (a different pin layer or ring, or a macro grid
# whose stripes cross them), which depends on the macro.
#
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
# One grid, for the orientations that keep the macro's supply sides vertical.
# `-grid_over_boundary` lets the top-level met4/met5 straps run across
# the macro and drop vias onto its pins, which is how a hard macro — an OpenRAM
# SRAM or a hardened partition — is tied into the top-level supply. The 2 um
# halo keeps the via stacks and strap ends off the macro edge. It needs the
# standard-cell rows cut at least as far around each macro, which tapcell.tcl
# does: pdngen fails with PDN-0008 when a halo reaches a row the macro does not
# sit on.
#
# This is the half of the hierarchical convention that lives at the top. The
# other half is the block-level grid above: a block hardened for consumption
# here must expose its supply on met5, and must not route signals on met5 in a
# way that would collide with the parent's straps.
####################################
# grid for: CORE_macro_grid_1
####################################
define_pdn_grid -name {CORE_macro_grid_1} -voltage_domains {CORE} -macro \
  -orient {R0 R180 MX MY} -halo {2.0 2.0 2.0 2.0} -default -grid_over_boundary
add_pdn_connect -grid {CORE_macro_grid_1} -layers {met4 met5}
