// Flat sky130hd build of demo_tiny_alu_subsys_synth_top.
//
// Identical to demo_tiny_alu_subsys_synth.f except that RB_SRAM_SKY130 swaps
// the flop array inside demo_tiny_alu_subsys_mem for the OpenRAM hard macro,
// which enters the netlist as a blackbox. The macro's LEF / Liberty / GDS come
// from the run's lef-paths / lib-paths / gds-paths, not from here.
+define+RB_SRAM_SKY130
-v ../apb/apb_intf.sv
-v ../common/ip_cdc_sync.sv
-v ../common/ip_cdc_handshake.sv
-v ../common/ip_async_fifo.sv
-v ../demo_tiny_alu/demo_tiny_alu.sv
demo_tiny_alu_subsys_csr_pkg.sv
-v demo_tiny_alu_subsys_csr.sv
-v demo_tiny_alu_subsys_compute.sv
-v sky130_sram_1kbyte_1rw1r_32x256_8_bb.sv
-v demo_tiny_alu_subsys_mem.sv
-v demo_tiny_alu_subsys_top.sv
demo_tiny_alu_subsys_synth_top.sv
