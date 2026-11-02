# The flat run's constraints (../../synth/demo_tiny_alu_subsys_hier/constraints_flat.sdc)
# with apb_clk at 12.6 ns instead of 20 ns.
#
# The worst setup path is the SRAM's read data out to prdata. The SRAM
# launches it on the falling clock edge, so it has half a period: at 20 ns it
# has slack to spare, at 12.6 ns it misses setup even after the flow's default
# timing repair, and the repair run in pnr.yaml has something to fix. The synthesised netlist is the
# same as the flat run's; only P&R reads this file.

create_clock -name apb_clk -period 12.6 [get_ports apb_clk]
create_clock -name cclk    -period 25.0 [get_ports cclk]

set_clock_groups -asynchronous \
    -group {apb_clk} \
    -group {cclk}

set_input_delay  4.0 -clock apb_clk [get_ports {paddr pprot psel penable pwrite pwdata pstrb apb_rst_n}]
set_output_delay 4.0 -clock apb_clk [get_ports {pready prdata pslverr}]
set_input_delay  5.0 -clock cclk    [get_ports {crst_n}]
