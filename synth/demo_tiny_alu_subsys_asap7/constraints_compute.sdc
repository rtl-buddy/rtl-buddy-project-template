# ASAP7 constraints for the demo_tiny_alu_subsys_compute partition.
#
# Times are in ps: the ASAP7 Liberty `time_unit` is 1 ps, and SDC values are
# read in the Liberty's unit. (The sky130hd twin,
# ../demo_tiny_alu_subsys_hier/constraints_compute.sdc, is in ns.) Capacitance
# is in fF, the ASAP7 Liberty `capacitive_load_unit`.
#
# A 600 ps (1.67 GHz) clock, which the routed design meets with margin.
# The I/O budget is 20% of the period at each boundary, as on sky130hd.

create_clock -name clk -period 600 [get_ports clk]

set data_inputs [get_ports { \
    rst_n src_sel \
    cmd_valid cmd_op* cmd_a* cmd_b* \
    fifo_rd_data* fifo_rd_empty }]

set_input_delay  120 -clock clk $data_inputs
set_output_delay 120 -clock clk [all_outputs]

set_driving_cell -lib_cell BUFx2_ASAP7_75t_R -pin Y $data_inputs
set_load 1.0 [all_outputs]
