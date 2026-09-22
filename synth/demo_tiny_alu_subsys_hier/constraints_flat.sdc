# sky130hd constraints for demo_tiny_alu_subsys_synth_top.
#
# Used by both the flat reference run and the top-level assembly run, so the
# two are compared under identical constraints — the only difference between
# them is whether the partitions are RTL or macros.
#
# Same two asynchronous domains as the Nangate45 constraints
# (../demo_tiny_alu_subsys/constraints.sdc), with the periods relaxed for a
# 130 nm process: sky130hd standard cells are several times slower than
# FreePDK45's, and the point of this example is a clean route with a connected
# PDN, not a frequency record.
#
#   apb_clk — 50 MHz APB host / CSR block
#   cclk    — 40 MHz compute core

create_clock -name apb_clk -period 20.0 [get_ports apb_clk]
create_clock -name cclk    -period 25.0 [get_ports cclk]

set_clock_groups -asynchronous \
    -group {apb_clk} \
    -group {cclk}

set_input_delay  4.0 -clock apb_clk [get_ports {paddr pprot psel penable pwrite pwdata pstrb apb_rst_n}]
set_output_delay 4.0 -clock apb_clk [get_ports {pready prdata pslverr}]
set_input_delay  5.0 -clock cclk    [get_ports {crst_n}]
