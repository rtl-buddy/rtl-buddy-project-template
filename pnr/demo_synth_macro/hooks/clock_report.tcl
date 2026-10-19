# `after-cts` hook of demo_synth_macro_sky130_hooks_pnr: writes the clock tree
# as clock_tree_synthesis built it, before the post-CTS legalization and timing
# repair change it, to clock_tree.rpt in the run's artefact directory
# (`$OUT_DIR`).

set rpt [file join $OUT_DIR clock_tree.rpt]
# Wire parasitics for the clock nets CTS just added, so skew and latency
# include their wires.
estimate_parasitics -placement
report_cts -out_file $rpt
report_clock_skew >> $rpt
report_clock_latency >> $rpt
puts "clock tree report: $rpt"
