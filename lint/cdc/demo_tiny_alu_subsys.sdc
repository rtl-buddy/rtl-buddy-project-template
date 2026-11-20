# SDC for the demo_tiny_alu_subsys CDC analysis.
#
# Two asynchronous clock domains: apb_clk (APB host + CSR block) and
# cclk (compute core). The design crosses between them via
# ip_cdc_handshake (data) and ip_cdc_sync (status flags); the lint
# pass should report zero violations against this constraint set.

create_clock -name apb_clk -period 10.0 [get_ports apb_clk]
create_clock -name cclk    -period 6.0  [get_ports cclk]
set_clock_groups -asynchronous \
    -group {apb_clk} \
    -group {cclk}

# apb_rst_n is used asynchronously by the handshake/sync IPs (negedge in
# the sensitivity list -> ARST pins, legitimately untimed) but the
# PeakRDL-generated CSR block samples it SYNCHRONOUSLY
# (`always_ff @(posedge clk) if(~rst_n) ...` -> $sdff SRST). A sync
# reset is captured on the clock edge like any data input, so it needs
# SDC typing; rtl-buddy-cdc >= 0.5.0 flags the omission (CDC-011).
set_input_delay -clock apb_clk 0 [get_ports apb_rst_n]

# The members of the `apb` interface port are top-level ports named
# `apb.<member>` (rtl-buddy-cdc >= 0.8.1; earlier releases had no port
# for them). The APB host drives them from apb_clk, so type the inputs;
# untyped, each one is an unconstrained source (CDC-011).
set_input_delay -clock apb_clk 0 [get_ports {apb.psel apb.penable apb.pwrite apb.pprot apb.paddr apb.pwdata apb.pstrb}]
