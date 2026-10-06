# Tap and endcap insertion for the asap7 platform.
#
# Referenced by `cfg-pdks.asap7.tapcell-tcl` in ../../root_config.yaml. The P&R
# flow sources it after macro placement and the macro keep-outs, before the
# power grid — the step where ORFS sources its TAPCELL_TCL.
#
# Adapted from OpenROAD-flow-scripts flow/platforms/asap7/openRoad/tapcell.tcl
# (BSD-3-Clause, The OpenROAD Project) at ORFS commit
# 2aeb23bcc3b5aa925abb991c4347ce73827b8b82, the commit pinned in
# ../../synth/demo_tiny_alu_subsys_asap7/download_pdk.sh (which also fetches
# the upstream file to pdk/asap7/openRoad/tapcell.tcl, for comparison).
#
# One change from upstream: rtl_buddy sources hook files as written, with no
# ORFS environment, so the three `$::env(...)` reads are filled in with the
# values ORFS' flow/platforms/asap7/config.mk gives them on an RVT build:
#
#   TAP_CELL_NAME       TAPCELL_ASAP7_75t_R   (tap master and endcap master)
#   MACRO_ROWS_HALO_X   2
#   MACRO_ROWS_HALO_Y   2

puts "Tap and End Cap cell insertion"
puts "  TAP Cell          : TAPCELL_ASAP7_75t_R"
puts "  ENDCAP Cell       : TAPCELL_ASAP7_75t_R"
puts "  Halo Around Macro : 2 2"
puts "  TAP Cell Distance : 25"

# allow user to set the distance between the edges of the macros
# and the beginning of the core rows with MACRO_ROW_HALO_?
tapcell \
  -distance 25 \
  -tapcell_master "TAPCELL_ASAP7_75t_R" \
  -endcap_master "TAPCELL_ASAP7_75t_R" \
  -halo_width_x 2 \
  -halo_width_y 2
