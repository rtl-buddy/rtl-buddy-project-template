# sky130hd constraints for the demo_tiny_alu_subsys_compute hardened partition.
#
# One clock, for the same reason as constraints_csr.sdc: the compute datapath
# and the demo_tiny_alu instance inside it are all on the compute clock, so its
# abstract is a single-domain timing model and the apb↔compute crossings stay
# in the top.
#
# The period matches cclk in constraints_flat.sdc. The I/O budget is 20% of the
# period at each boundary; the top-level logic this block talks to is the
# handshake and async-FIFO glue, which registers on both sides.

create_clock -name clk -period 25.0 [get_ports clk]

set data_inputs [get_ports { \
    rst_n src_sel \
    cmd_valid cmd_op* cmd_a* cmd_b* \
    fifo_rd_data* fifo_rd_empty }]

set_input_delay  5.0 -clock clk $data_inputs
set_output_delay 5.0 -clock clk [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin X $data_inputs
set_load 0.05 [all_outputs]
