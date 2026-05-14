# Synthesis + P&R constraints for demo_tiny_alu_subsys_synth_top.
#
# Two asynchronous clock domains:
#   apb_clk — 100 MHz APB host / CSR block
#   cclk    — 166 MHz compute core
# Crossings between them go through ip_cdc_handshake / ip_cdc_sync;
# treat the two as fully async at synthesis and P&R.

create_clock -name apb_clk -period 10.0 [get_ports apb_clk]
create_clock -name cclk    -period 6.0  [get_ports cclk]

set_clock_groups -asynchronous \
    -group {apb_clk} \
    -group {cclk}

set_input_delay  2.0 -clock apb_clk [get_ports {paddr pprot psel penable pwrite pwdata pstrb apb_rst_n}]
set_output_delay 2.0 -clock apb_clk [get_ports {pready prdata pslverr}]
set_input_delay  1.5 -clock cclk    [get_ports {crst_n}]
