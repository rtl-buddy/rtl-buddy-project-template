# sky130hd constraints for the demo_tiny_alu_subsys_csr hardened partition.
#
# Hand-written per-partition constraints, which is what rtl_buddy#95 calls for
# in the pipeclean: deriving a block budget from the top-level SDC is timing
# budgeting, and that is out of scope there and here.
#
# One clock. The CSR block lives entirely in apb_clk, and that is the property
# that makes it a good hardening target — its Liberty abstract comes out as a
# clean single-domain timing model, with every clock-domain crossing left
# outside it in the top's standard-cell logic where `rb cdc` analyses it.
#
# The period matches apb_clk in constraints_flat.sdc. The I/O budget is a flat
# 20% of the period at each boundary, leaving 60% for the block itself; the
# top-level logic on the other side of these ports is the APB port fan-in and
# the hwif fan-out, neither of which is deep.
#
# The data inputs are listed rather than derived. OpenROAD's OpenSTA has no
# `remove_from_collection`, so there is no way to say "all_inputs except the
# clock"; and `hwif_in` is the CSR package's struct flattened to a bus, so its
# bits have to be matched with a pattern.

create_clock -name clk -period 20.0 [get_ports clk]

set data_inputs [get_ports { \
    rst_n \
    s_apb_psel s_apb_penable s_apb_pwrite \
    s_apb_pprot* s_apb_paddr* s_apb_pwdata* s_apb_pstrb* \
    hwif_in* }]

set_input_delay  4.0 -clock clk $data_inputs
set_output_delay 4.0 -clock clk [all_outputs]

# Without these the block sees ideal drivers and zero load, and the abstract it
# produces is optimistic at exactly the boundary the top-level STA then trusts.
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin X $data_inputs
set_load 0.05 [all_outputs]
