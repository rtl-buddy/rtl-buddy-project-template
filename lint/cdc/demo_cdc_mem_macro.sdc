# Two asynchronous clocks: host (clk_h) and memory (clk_m).
create_clock -name clk_h -period 10.0 [get_ports clk_h]
create_clock -name clk_m -period 7.0  [get_ports clk_m]
set_clock_groups -asynchronous -group {clk_h} -group {clk_m}

# Host-domain write-port inputs (clk_h). They are launched into the req/ack
# handshake on a we_h & ready_h cycle, which then holds them across the
# crossing — so their launch domain is clk_h.
set_input_delay -clock clk_h 0 [get_ports we_h]
set_input_delay -clock clk_h 0 [get_ports addr_h]
set_input_delay -clock clk_h 0 [get_ports wdata_h]
