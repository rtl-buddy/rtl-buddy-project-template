# Clocks and I/O delays of demo_tiny_alu_subsys_synth_top, shared by every
# corner. Each corner's SDC (constraints_<corner>.sdc) sources this file and
# adds its own clock uncertainty.
#
#   apb_clk  25 MHz APB host / CSR block
#   cclk     40 MHz compute core

create_clock -name apb_clk -period 40.0 [get_ports apb_clk]
create_clock -name cclk    -period 25.0 [get_ports cclk]

set_clock_groups -asynchronous \
    -group {apb_clk} \
    -group {cclk}

set_input_delay  4.0 -clock apb_clk [get_ports {paddr pprot psel penable pwrite pwdata pstrb apb_rst_n}]
set_output_delay 4.0 -clock apb_clk [get_ports {pready prdata pslverr}]
set_input_delay  5.0 -clock cclk    [get_ports {crst_n}]
