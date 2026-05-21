// vim: set ts=2 sw=2 et :
//
// Source-synchronous clock-forwarding chain reference design.
//
//     A ──► B0 ──► C0
//      └──► B1 ──► C1
//
// Only ck_a enters the design. Each upstream block produces a
// forwarded clock on an internal net via a divide-by-2 flop (the
// "buffer" — a real cell so each forwarded clock keeps a distinct
// net identity in the flattened netlist; the CDC tool keys on those
// internal pins through ``create_generated_clock`` in the SDC).
//
// The data path is one bit per stage, registered in each block on
// the block's local clock. With the system SDC declaring every
// forwarded clock as a ``create_generated_clock`` rooted at ck_a,
// CDC lint reports zero violations.
//
// The same RTL is synthesizable (generic Yosys) and simulatable
// (basic propagation TB under verif/demo_cdc_src_sync/).

module demo_cdc_src_sync_block_a (
  input  logic clk_in,
  input  logic rst_n,
  input  logic d_in,
  output logic clk_out_b0,
  output logic clk_out_b1,
  output logic a_q
);
  // Two divide-by-2 forwarded clocks, one per downstream B block.
  // Real flops keep clk_out_b0 / clk_out_b1 at distinct net bits in
  // the flattened netlist, which is what the SDC pin targets key on.
  logic div_b0, div_b1;
  always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
      div_b0 <= 1'b0;
      div_b1 <= 1'b0;
    end else begin
      div_b0 <= ~div_b0;
      div_b1 <= ~div_b1;
    end
  end
  assign clk_out_b0 = div_b0;
  assign clk_out_b1 = div_b1;

  // Block A's data flop, in the ck_a domain.
  logic q;
  always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) q <= 1'b0;
    else        q <= d_in;
  end
  assign a_q = q;
endmodule

module demo_cdc_src_sync_block_b (
  input  logic clk_in,
  input  logic rst_n,
  input  logic d_in,
  output logic clk_out,
  output logic b_q
);
  logic div;
  always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) div <= 1'b0;
    else        div <= ~div;
  end
  assign clk_out = div;

  logic q;
  always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) q <= 1'b0;
    else        q <= d_in;
  end
  assign b_q = q;
endmodule

module demo_cdc_src_sync_block_c (
  input  logic clk_in,
  input  logic rst_n,
  input  logic d_in,
  output logic c_q
);
  logic q;
  always_ff @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) q <= 1'b0;
    else        q <= d_in;
  end
  assign c_q = q;
endmodule

module demo_cdc_src_sync_top (
  input  logic ck_a,
  input  logic rst_n,
  input  logic d_in,
  output logic q_out_c0,
  output logic q_out_c1
);

  logic a_q, b0_q, b1_q;
  logic ck_b0_int, ck_b1_int, ck_c0_int, ck_c1_int;

  demo_cdc_src_sync_block_a u_a (
    .clk_in     (ck_a),
    .rst_n      (rst_n),
    .d_in       (d_in),
    .clk_out_b0 (ck_b0_int),
    .clk_out_b1 (ck_b1_int),
    .a_q        (a_q)
  );

  demo_cdc_src_sync_block_b u_b0 (
    .clk_in  (ck_b0_int),
    .rst_n   (rst_n),
    .d_in    (a_q),
    .clk_out (ck_c0_int),
    .b_q     (b0_q)
  );

  demo_cdc_src_sync_block_b u_b1 (
    .clk_in  (ck_b1_int),
    .rst_n   (rst_n),
    .d_in    (a_q),
    .clk_out (ck_c1_int),
    .b_q     (b1_q)
  );

  demo_cdc_src_sync_block_c u_c0 (
    .clk_in (ck_c0_int),
    .rst_n  (rst_n),
    .d_in   (b0_q),
    .c_q    (q_out_c0)
  );

  demo_cdc_src_sync_block_c u_c1 (
    .clk_in (ck_c1_int),
    .rst_n  (rst_n),
    .d_in   (b1_q),
    .c_q    (q_out_c1)
  );

endmodule
