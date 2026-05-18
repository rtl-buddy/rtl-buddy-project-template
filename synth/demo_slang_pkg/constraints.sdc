# 100 MHz target. Yosys backend extracts the period and passes it to
# ABC as `-D <period_ps>` for timing-driven mapping (when a Liberty is
# also provided; tech-independent run ignores it).
create_clock -period 10.0 [get_ports clk]
set_input_delay  2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]
