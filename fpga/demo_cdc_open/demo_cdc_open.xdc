# Top XDC for the open FPGA implementation of demo_cdc_open.
#
# Two independent clocks; the crossings between them are the whole point of
# the block. `set_clock_groups -asynchronous` declares clk_a/clk_b
# unrelated so the implementation tool does not try to time the CDC paths —
# the timing exception that lets the synchronizers do their job and keeps
# `wns_ns`/`timing_met` meaningful for the real (intra-domain) paths.
#
# Portability note: `create_clock` is consumed by both Vivado and the open
# nextpnr-xilinx flow; `set_clock_groups` is consumed by Vivado and quietly
# ignored by nextpnr-xilinx (it does not time unrelated clock domains
# against each other), so this one XDC drives either backend unchanged.
#
# IOSTANDARD: this is an IP-level run with no board pinout — no LOC pin
# placement is given (the P&R tool auto-assigns I/O sites). nextpnr-xilinx
# still requires an explicit IOSTANDARD on every top port (Vivado would
# default it), so a generic LVCMOS33 is assigned to all ports below.

# --- Clocks ---------------------------------------------------------------
create_clock -name clk_a -period 10.0 [get_ports clk_a]
create_clock -name clk_b -period 7.5  [get_ports clk_b]

set_clock_groups -asynchronous \
    -group {clk_a} \
    -group {clk_b}

# --- I/O standards (IP-level; no board LOC) ------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports clk_a]
set_property IOSTANDARD LVCMOS33 [get_ports clk_b]
set_property IOSTANDARD LVCMOS33 [get_ports arst_a_n]
set_property IOSTANDARD LVCMOS33 [get_ports arst_b_n]
set_property IOSTANDARD LVCMOS33 [get_ports flag_a]
set_property IOSTANDARD LVCMOS33 [get_ports flag_b]
set_property IOSTANDARD LVCMOS33 [get_ports gray_incr_a]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[0]]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[1]]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[2]]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[3]]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[4]]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[5]]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[6]]
set_property IOSTANDARD LVCMOS33 [get_ports gray_count_b[7]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_valid_a]
set_property IOSTANDARD LVCMOS33 [get_ports hs_ready_a]
set_property IOSTANDARD LVCMOS33 [get_ports hs_valid_b]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[0]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[1]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[2]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[3]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[4]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[5]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[6]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[7]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[8]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[9]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[10]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[11]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[12]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[13]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[14]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_a[15]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[0]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[1]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[2]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[3]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[4]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[5]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[6]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[7]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[8]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[9]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[10]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[11]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[12]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[13]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[14]]
set_property IOSTANDARD LVCMOS33 [get_ports hs_data_b[15]]
