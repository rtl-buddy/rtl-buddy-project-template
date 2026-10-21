# The ff corner's constraints: the shared clocks and I/O delays, plus this
# corner's clock uncertainty.
source [file join [file dirname [info script]] clocks_io.sdc]

set_clock_uncertainty -setup 0.10 [all_clocks]
set_clock_uncertainty -hold  0.10 [all_clocks]
