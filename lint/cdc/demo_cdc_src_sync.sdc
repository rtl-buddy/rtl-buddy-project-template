# SDC for the demo_cdc_src_sync CDC analysis. Demonstrates the
# source-synchronous methodology: only ck_a enters the design; each
# forwarded clock is declared with create_generated_clock at the
# internal pin where the block's divider Q drives the forwarded net.
# Every generated clock resolves back to ck_a's master, so CDC lint
# must report zero violations across all four A→B / B→C links.

create_clock -name ck_a -period 10.0 [get_ports ck_a]

# A → B0, A → B1: A's two divide-by-2 outputs.
create_generated_clock -name ck_b0 -source [get_ports ck_a] \
    -master_clock ck_a -divide_by 2 [get_pins u_a/clk_out_b0]
create_generated_clock -name ck_b1 -source [get_ports ck_a] \
    -master_clock ck_a -divide_by 2 [get_pins u_a/clk_out_b1]

# B0 → C0, B1 → C1: each B block's divide-by-2 output. The -source
# pin is the upstream forwarded clock's pin (internal-pin chaining).
create_generated_clock -name ck_c0 -source [get_pins u_a/clk_out_b0] \
    -master_clock ck_b0 -divide_by 2 [get_pins u_b0/clk_out]
create_generated_clock -name ck_c1 -source [get_pins u_a/clk_out_b1] \
    -master_clock ck_b1 -divide_by 2 [get_pins u_b1/clk_out]

set_input_delay -clock ck_a 0.0 [get_ports d_in]
