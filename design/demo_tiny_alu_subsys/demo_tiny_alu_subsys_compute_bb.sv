// Blackbox declaration for the demo_tiny_alu_subsys_compute hardened partition.
//
// Ports only, no body — the counterpart of demo_tiny_alu_subsys_csr_bb.sv for
// partition B. In the top-level assembly build the compute datapath, including
// its demo_tiny_alu instance, is a hard macro: extent from the abstract LEF,
// timing from the Liberty model, layout from the GDS, all three written by
// pnr/demo_tiny_alu_subsys_hier/harden.sh.
//
// The port list must stay identical to demo_tiny_alu_subsys_compute.sv's.

`timescale 1ns/10ps

(* blackbox *)
module demo_tiny_alu_subsys_compute (
  input  wire        clk,
  input  wire        rst_n,

  input  wire        src_sel,

  input  wire        cmd_valid,
  input  wire [2:0]  cmd_op,
  input  wire [7:0]  cmd_a,
  input  wire [7:0]  cmd_b,

  output wire        fifo_rd_en,
  input  wire [18:0] fifo_rd_data,
  input  wire        fifo_rd_empty,

  output wire        result_valid,
  output wire [7:0]  result_y,
  output wire        result_zf,
  output wire        result_cf,
  output wire        result_nf,
  output wire        result_vf,

  output wire        busy
);
endmodule
