# 5 ns on the one clock. demo_hard_macro's Liberty gives q a rising_edge arc of
# 0.8 ns off clk, so macro q -> capture flop is the path worth looking at: it is
# the path that only exists if the macro made it into the timing graph at all.
create_clock -name clk -period 5.0 [get_ports clk]

set_input_delay  1.0 -clock clk [get_ports {rst_n en d[*]}]
set_output_delay 1.0 -clock clk [get_ports q[*]]
