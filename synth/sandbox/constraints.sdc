# 100 MHz target. The Yosys backend extracts the clock period and passes
# it to ABC as `-D <period_ps>` for timing-driven technology mapping.
create_clock -period 10.0 [get_ports clk]
set_input_delay  2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]
