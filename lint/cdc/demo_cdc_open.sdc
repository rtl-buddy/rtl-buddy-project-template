# SDC for the demo_cdc_open CDC analysis. Two asynchronous clocks bridged
# by the portable synchronizer block — `set_clock_groups -asynchronous`
# tells the analyzer the clk_a/clk_b relationship is unconstrained, exactly
# the case the 2FF / Gray / handshake / reset-sync structures are built to
# cross. The recognition pass must report zero violations.
#
# The same clock declarations + async grouping carry over to the open FPGA
# flow's top XDC (../../fpga/demo_cdc_open/demo_cdc_open.xdc).

create_clock -name clk_a -period 10.0 [get_ports clk_a]
create_clock -name clk_b -period 7.5  [get_ports clk_b]
set_clock_groups -asynchronous \
    -group {clk_a} \
    -group {clk_b}
