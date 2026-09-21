// Top-level assembly build of demo_tiny_alu_subsys_synth_top.
//
// Same RTL as demo_tiny_alu_subsys_sky130.f for everything the top itself owns
// — the CDC glue, the reset synchroniser, the apb-side result latching and the
// memory wrapper — but the two partitions that are hardened separately enter as
// blackboxes rather than as RTL:
//
//   demo_tiny_alu_subsys_csr      hardened by pnr/demo_tiny_alu_subsys_hier
//   demo_tiny_alu_subsys_compute  hardened by pnr/demo_tiny_alu_subsys_hier
//   sky130_sram_1kbyte_1rw1r_32x256_8   third-party OpenRAM macro
//
// All three reach the backend as LEF + Liberty (+ GDS for stream-out) through
// the run's lef-paths / lib-paths / gds-paths. The CSR package is still read:
// it declares the hwif struct types that the CSR blackbox's ports are typed
// with and that the top drives.
+define+RB_SRAM_SKY130
-v ../apb/apb_intf.sv
-v ../common/ip_cdc_sync.sv
-v ../common/ip_cdc_handshake.sv
-v ../common/ip_async_fifo.sv
demo_tiny_alu_subsys_csr_pkg.sv
-v demo_tiny_alu_subsys_csr_bb.sv
-v demo_tiny_alu_subsys_compute_bb.sv
-v sky130_sram_1kbyte_1rw1r_32x256_8_bb.sv
-v demo_tiny_alu_subsys_mem.sv
-v demo_tiny_alu_subsys_top.sv
demo_tiny_alu_subsys_synth_top.sv
