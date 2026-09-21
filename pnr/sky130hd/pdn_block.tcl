# Block-level power-delivery network for the sky130hd platform.
#
# Referenced by `cfg-pdks.sky130hd_block.pdn-config` in ../../root_config.yaml,
# which is the sky130hd entry with this file in place of pdn.tcl. Select it
# through the `sky130hd_tt_block` P&R platform when a run is hardening a block
# that a larger design will instantiate as a macro.
#
# This is the block half of the hierarchical PDN convention. The top half is in
# pdn.tcl; between them the rule is one sentence:
#
#   **A block owns met1 through met4. met5 belongs to whoever instantiates it.**
#
# That is not a preference, it is what makes the assembly route at all:
#
#   * The parent ties a macro in by running its met5 straps across the macro
#     (`-grid_over_boundary`) and dropping met4/met5 vias onto the macro's power
#     pins. So the pins have to be on met4 and the macro must not have anything
#     of its own on met5.
#
#   * `write_abstract_lef -bloat_occupied_layers`, which
#     ../demo_tiny_alu_subsys_hier/harden.sh uses, turns every layer the block
#     occupied into a blockage over the block's whole footprint. A block that
#     puts one power strap on met5 therefore blocks met5 across itself, the
#     parent's straps cannot cross it, and `pdngen` reports the macro's grid as
#     containing no shapes and fails the run with PDN-0233.
#
#   * It is also the convention the third-party macro in this example already
#     follows: the OpenRAM SRAM exposes vccd1 / vssd1 on met4 and met3. A
#     hardened partition that does the same is indistinguishable from it at the
#     top, which is the property the whole flow depends on.
#
# The block's signal routing is held to met1-met4 by the `sky130hd_tt_block`
# P&R platform's `routing-layers`, for the same reason.
#
# Adapted from OpenROAD-flow-scripts flow/platforms/sky130hd/pdn.tcl
# (BSD-3-Clause, The OpenROAD Project). Differences from that file: the straps
# stop at met4 and are exposed there rather than on met5, and there are no
# macro grids, because a leaf block being hardened contains no macros.

####################################
# global connections
####################################
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDPE$}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDCE$}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VPWR}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VPB}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSS$} -ground
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSSE$}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VGND}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VNB}
global_connect

####################################
# voltage domains
####################################
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

####################################
# standard cell grid
####################################
# met1 followpins on the cell rails, met4 straps above them, and the grid
# exposed on met4 — which is what `write_abstract_lef` turns into the VDD / VSS
# pins of the abstract. Nothing on met5.
define_pdn_grid -name {grid} -voltage_domains {CORE} -pins {met4}
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {5.44} -offset {0} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.600} -pitch {27.140} -offset {13.570}
add_pdn_connect -grid {grid} -layers {met1 met4}
