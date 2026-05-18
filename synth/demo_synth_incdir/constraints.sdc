# 100 MHz target. Matches the demo_tiny_alu constraints — kept simple
# so the only interesting thing about this run is the filelist `+incdir+`
# handling (rtl_buddy#69).
create_clock -period 10.0 [get_ports clk]
set_input_delay  2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]
