# SDC for the ip_cdc_handshake CDC analysis. Two asynchronous clocks
# whose relationship is precisely what the handshake is designed to
# bridge — the lint pass must report zero violations.

create_clock -name src_clk -period 10.0 [get_ports src_clk]
create_clock -name dst_clk -period 7.5  [get_ports dst_clk]
set_clock_groups -asynchronous \
    -group {src_clk} \
    -group {dst_clk}

# Type the source-domain data/control inputs into src_clk's domain.
# `src_valid` / `src_data` originate in the source domain and are
# carried across to dst_clk by the handshake itself; declaring their
# launch clock keeps CDC-011 (unconstrained primary input) silent so
# the protocol-safe crossings aren't flagged as untyped (rtl-buddy-cdc
# enforces input-domain typing from 0.2.0 onward).
set_input_delay -clock src_clk 1.0 [get_ports src_valid]
set_input_delay -clock src_clk 1.0 [get_ports src_data]
