// demo_cdc_open_top — portable CDC block for the OPEN FPGA flow.
//
// Exercises every common clock-domain-crossing style across two
// asynchronous clocks (clk_a -> clk_b) using only vendor-neutral RTL:
//
//   * reset synchronizer per domain      (cdc_open_reset_sync)
//   * single-bit 2-flop level crossing   (cdc_open_sync)
//   * multi-bit Gray-coded bus           (cdc_open_gray_bus)
//   * req/ack handshake with payload     (cdc_open_handshake)
//
// All synchronizers carry only (* ASYNC_REG = "TRUE" *) / (* keep *) —
// no XPM, no UNISIM — so the identical RTL elaborates for ASIC and FPGA
// and synthesises under both Yosys (`synth_xilinx`) and Vivado. The
// companion flows:
//   * recognition  — `rb cdc`  (../../lint/cdc/cdc.yaml, demo_cdc_open.sdc)
//   * open impl    — `rb fpga tool: openxc7`
//                    (../../fpga/demo_cdc_open/fpga.yaml, demo_cdc_open.xdc)

module demo_cdc_open_top #(
  parameter int BUS_W = 8,
  parameter int PAY_W = 16
)(
  // Two asynchronous clock domains, each with an async-assert reset.
  input  logic               clk_a,
  input  logic               clk_b,
  input  logic               arst_a_n,
  input  logic               arst_b_n,

  // Single-bit level crossing (clk_a -> clk_b)
  input  logic               flag_a,
  output logic               flag_b,

  // Gray-coded bus crossing (clk_a -> clk_b)
  input  logic               gray_incr_a,
  output logic [BUS_W-1:0]    gray_count_b,

  // Req/ack handshake crossing (clk_a -> clk_b)
  input  logic               hs_valid_a,
  output logic               hs_ready_a,
  input  logic [PAY_W-1:0]    hs_data_a,
  output logic               hs_valid_b,
  output logic [PAY_W-1:0]    hs_data_b
);

  // Per-domain synchronized resets.
  logic rst_a_n;
  logic rst_b_n;

  cdc_open_reset_sync #(.STAGES(2)) u_reset_sync_a (
    .clk(clk_a), .arst_n(arst_a_n), .rst_n(rst_a_n)
  );
  cdc_open_reset_sync #(.STAGES(2)) u_reset_sync_b (
    .clk(clk_b), .arst_n(arst_b_n), .rst_n(rst_b_n)
  );

  // Register the source flag in clk_a before crossing, so the
  // synchronizer samples a stable flop output (not a glitchy boundary
  // port) — the launch register a clean CDC crossing expects.
  logic flag_a_q;
  always_ff @(posedge clk_a or negedge rst_a_n) begin
    if (!rst_a_n) flag_a_q <= 1'b0;
    else          flag_a_q <= flag_a;
  end

  // Single-bit level synchronizer into clk_b.
  cdc_open_sync #(.WIDTH(1), .STAGES(2)) u_flag_sync (
    .clk(clk_b), .rst_n(rst_b_n), .d(flag_a_q), .q(flag_b)
  );

  // Multi-bit Gray-coded counter crossing clk_a -> clk_b.
  cdc_open_gray_bus #(.WIDTH(BUS_W)) u_gray_bus (
    .src_clk   (clk_a),
    .src_rst_n (rst_a_n),
    .src_incr  (gray_incr_a),
    .src_count (/* unused */),
    .dst_clk   (clk_b),
    .dst_rst_n (rst_b_n),
    .dst_count (gray_count_b)
  );

  // Req/ack handshake with held payload crossing clk_a -> clk_b.
  cdc_open_handshake #(.WIDTH(PAY_W)) u_handshake (
    .src_clk   (clk_a),
    .src_rst_n (rst_a_n),
    .src_valid (hs_valid_a),
    .src_ready (hs_ready_a),
    .src_data  (hs_data_a),
    .dst_clk   (clk_b),
    .dst_rst_n (rst_b_n),
    .dst_valid (hs_valid_b),
    .dst_data  (hs_data_b)
  );

endmodule
