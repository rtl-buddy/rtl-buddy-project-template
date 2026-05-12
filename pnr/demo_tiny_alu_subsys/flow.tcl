# OpenROAD flow for demo_tiny_alu_subsys on Nangate45.
#
# Stages: read -> floorplan -> place pins -> global place -> CTS ->
# detail place -> global route -> detail route -> write DEF + GDS.

source [file join [file dirname [info script]] config.tcl]

puts ">>> Reading Liberty + LEF"
read_liberty $LIBERTY
read_lef     $TECH_LEF
read_lef     $MACRO_LEF

puts ">>> Reading netlist"
read_verilog $NETLIST
link_design  $DESIGN

puts ">>> Reading SDC"
read_sdc $SDC_FILE

puts ">>> Initializing floorplan"
initialize_floorplan \
    -site            $SITE \
    -utilization     [expr {$CORE_UTIL * 100}] \
    -aspect_ratio    $CORE_ASPECT \
    -core_space      $CORE_MARGIN

# Tracks: defaults pulled from LEF SITE pitches.
make_tracks

puts ">>> IO pin placement"
place_pins -hor_layers metal3 -ver_layers metal2

puts ">>> Tap + endcap (skipped — small block, no tap cells needed)"

puts ">>> Tie cells"
insert_tiecells $TIEHI_CELL_PORT
insert_tiecells $TIELO_CELL_PORT

puts ">>> Global placement"
global_placement -density 0.7 -pad_left 1 -pad_right 1

puts ">>> Resize"
estimate_parasitics -placement
repair_design

puts ">>> Detail placement (legalize)"
detailed_placement

puts ">>> Clock tree synthesis"
set_propagated_clock [all_clocks]
clock_tree_synthesis \
    -root_buf $CTS_BUF \
    -buf_list $CTS_BUF \
    -sink_clustering_enable

puts ">>> Detail placement (post-CTS)"
detailed_placement

puts ">>> Post-CTS timing repair"
estimate_parasitics -placement
repair_timing -hold

puts ">>> Global route"
set_routing_layers -signal metal2-metal8 -clock metal4-metal8
global_route -congestion_iterations 20

puts ">>> Detail route"
detailed_route \
    -output_drc      $OUT_DIR/route.drc.rpt \
    -output_maze     $OUT_DIR/route.maze.log \
    -verbose 0

puts ">>> Fill insertion"
filler_placement $FILL_CELLS

puts ">>> Final reports"
estimate_parasitics -global_routing
report_design_area
report_worst_slack -max
report_worst_slack -min
report_tns
report_checks -path_delay max -fields {slew cap input nets fanout} -format full_clock_expanded > $OUT_DIR/timing.rpt

puts ">>> Write outputs"
write_def     $OUT_DIR/${DESIGN}.def
write_verilog $OUT_DIR/${DESIGN}.routed.v
write_sdc     $OUT_DIR/${DESIGN}.routed.sdc

# GDS streamout. OpenROAD's built-in `write_gds` is not always available
# (depends on build flags); when missing, the canonical path is to hand
# the routed DEF + cell GDS to KLayout. Both paths land here so the
# prototype keeps working on either build.
puts ">>> GDS streamout"
if {[llength [info commands write_gds]] > 0} {
    write_gds -lib_name nangate45 -map_file "" -corner [list] -gds [list $MACRO_GDS] $OUT_DIR/${DESIGN}.gds
} else {
    puts "    write_gds unavailable in this OpenROAD build."
    puts "    Run: klayout -zz -rd design_name=$DESIGN \\"
    puts "                 -rd in_def=$OUT_DIR/${DESIGN}.def \\"
    puts "                 -rd in_gds=$MACRO_GDS \\"
    puts "                 -rd out_gds=$OUT_DIR/${DESIGN}.gds \\"
    puts "                 -r <path-to>/def2gds.py"
}

puts ">>> DONE"
exit 0
