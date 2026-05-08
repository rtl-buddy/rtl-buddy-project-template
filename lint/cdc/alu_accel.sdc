# SDC for the alu_accel CDC analysis.
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
