# `after-reports` hook of demo_synth_macro_sky130_hooks_pnr: writes the worst
# path into the hard macro and the worst path out of it to macro_paths.rpt in
# the run's artefact directory (`$OUT_DIR`). It runs after rb's final reports,
# on the parasitics they read (the SPEF OpenRCX extracted from the routed
# design), so its slacks match timing.rpt, which holds only the worst path of
# the whole design.

set rpt [file join $OUT_DIR macro_paths.rpt]
report_checks -path_delay max -to [get_pins i_macro/d*] \
  -fields {slew cap input_pins} > $rpt
report_checks -path_delay max -through [get_pins i_macro/q*] \
  -fields {slew cap input_pins} >> $rpt
puts "macro path report: $rpt"
