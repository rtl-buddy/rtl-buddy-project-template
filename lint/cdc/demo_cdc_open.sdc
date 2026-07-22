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

# Type the clk_a-domain data/control inputs into clk_a's domain. They
# originate in clk_a and are carried to clk_b by the portable CDC
# structures below; declaring their launch clock keeps CDC-011
# (unconstrained primary input) silent and gives the Gray-bus crossing
# a real source domain so its gray-coding is recognised (no CDC-004).
# rtl-buddy-cdc enforces input-domain typing from 0.2.0 onward.
set_input_delay -clock clk_a 1.0 [get_ports flag_a]
set_input_delay -clock clk_a 1.0 [get_ports gray_incr_a]
set_input_delay -clock clk_a 1.0 [get_ports hs_valid_a]
set_input_delay -clock clk_a 1.0 [get_ports hs_data_a]
