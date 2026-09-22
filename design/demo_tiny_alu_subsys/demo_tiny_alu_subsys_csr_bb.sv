// Blackbox declaration for the demo_tiny_alu_subsys_csr hardened partition.
//
// Ports only, no body. Used by the top-level assembly build
// (demo_tiny_alu_subsys_sky130_asm.f), where the CSR block is not synthesized
// with the top but consumed as a hard macro: the extent comes from the abstract
// LEF and the timing from the Liberty model that
// pnr/demo_tiny_alu_subsys_hier/harden.sh writes out of the partition's own
// routed result.
//
// The port list must stay identical to the generated module's — same names,
// same order, same types. The generated file is
// demo_tiny_alu_subsys_csr.sv, itself written by
// gen_demo_tiny_alu_subsys_csr.sh from the RDL; re-run that script and this
// file has to follow, because the netlist the top instantiates and the netlist
// the partition was hardened from have to agree pin for pin.
//
// hwif_in / hwif_out keep their struct types rather than being flattened by
// hand: the struct declarations in demo_tiny_alu_subsys_csr_pkg are the only
// definition of how those bits are ordered, and re-stating the layout here
// would be a second, divergent source of truth.

`timescale 1ns/10ps

(* blackbox *)
module demo_tiny_alu_subsys_csr (
  input  wire        clk,
  input  wire        rst_n,

  input  wire        s_apb_psel,
  input  wire        s_apb_penable,
  input  wire        s_apb_pwrite,
  input  wire [2:0]  s_apb_pprot,
  input  wire [5:0]  s_apb_paddr,
  input  wire [31:0] s_apb_pwdata,
  input  wire [3:0]  s_apb_pstrb,
  output wire        s_apb_pready,
  output wire [31:0] s_apb_prdata,
  output wire        s_apb_pslverr,

  input  demo_tiny_alu_subsys_csr_pkg::demo_tiny_alu_subsys_csr__in_t  hwif_in,
  output demo_tiny_alu_subsys_csr_pkg::demo_tiny_alu_subsys_csr__out_t hwif_out
);
endmodule
