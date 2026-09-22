// Simulation build of demo_tiny_alu_subsys_top with the real OpenRAM macro.
//
// Same RTL as demo_tiny_alu_subsys.f, except RB_SRAM_SKY130 points
// demo_tiny_alu_subsys_mem at sky130_sram_1kbyte_1rw1r_32x256_8 and the
// behavioural model that OpenRAM ships alongside the macro's physical views
// supplies its body. That file is not vendored — it arrives with the rest of
// the macro's collateral via synth/demo_tiny_alu_subsys_hier/download_pdk.sh,
// so a test rooted here is a deferred-tier test.
//
// This is the counterpart of design/demo_synth_macro's blackbox/model split:
// the synthesis builds read sky130_sram_1kbyte_1rw1r_32x256_8_bb.sv, a port-only
// blackbox, and simulation reads the vendor model. Neither ever sees the other.
+define+RB_SRAM_SKY130
-v ../apb/apb_intf.sv
-v ../common/ip_cdc_sync.sv
-v ../common/ip_cdc_handshake.sv
-v ../common/ip_async_fifo.sv
-v ../demo_tiny_alu/demo_tiny_alu.sv
demo_tiny_alu_subsys_csr_pkg.sv
-v demo_tiny_alu_subsys_csr.sv
-v demo_tiny_alu_subsys_compute.sv
+incdir+../../pdk/sky130_sram
-v sky130_sram_model_wrap.sv
-v demo_tiny_alu_subsys_mem.sv
demo_tiny_alu_subsys_top.sv
