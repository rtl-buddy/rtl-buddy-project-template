# The hardened block on its own: one clock, the same 5 ns as the top, and 1 ns
# of the period left to the parent on each side of the boundary. The block's
# `write_timing_model` abstract is characterised against these, so its
# setup check on d and its clk -> q arc are what the top then times against.
create_clock -name clk -period 5.0 [get_ports clk]

set_input_delay  1.0 -clock clk [get_ports {en d[*]}]
set_output_delay 1.0 -clock clk [get_ports q[*]]
