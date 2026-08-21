// ip_cdc_handshake — 4-phase request/ack vector CDC.
//
// Transfers a multi-bit payload across two clock domains using a
// req/ack handshake plus level-synchronizers on the control bits. The
// payload is sampled by the destination only when `req` has been seen
// on the destination side, so wide vectors stay coherent without
// gray coding.
//
// Throughput: 1 transfer per ~4×max(src_period, dst_period). Use a
// proper async FIFO if you need higher rate.
//
// The `(* cdc_handshake *)` attributes mark the three participating
// registers (source req toggle, held payload, destination capture) so
// a structure-only CDC linter doesn't flag the protocol-safe paths as
// false positives. rtl-buddy-cdc recognises the attribute and suppresses
// CDC-013 on the backpressured toggle, CDC-020 on the held payload,
// CDC-001 on the single-register capture, and CDC-014 on post-capture
// decode comb (rtl-buddy-cdc#247). Older analyzers ignore the unknown
// attribute, so it's safe to carry unconditionally.
//
// See spec/ip_cdc_handshake/README.md.

// rbsch: leaf
// Timescale matches demo_tiny_alu.sv (slang errors on mixed `timescale
// presence within a compilation unit — LRM 3.14.2.3).
`timescale 1ns/10ps

module ip_cdc_handshake #(
  parameter int WIDTH = 8
)(
  // Source domain
  input  logic              src_clk,
  input  logic              src_rst_n,
  input  logic              src_valid,    // pulse high to launch a transfer
  output logic              src_ready,    // 1 when ready to accept new src_valid
  input  logic [WIDTH-1:0]  src_data,

  // Destination domain
  input  logic              dst_clk,
  input  logic              dst_rst_n,
  output logic              dst_valid,    // 1-cycle pulse on dst_clk per transfer
  (* cdc_handshake *)
  output logic [WIDTH-1:0]  dst_data      // single-register capture (CDC-001/014 safe)
);

  // Source-side req level toggles each accepted transfer
  (* cdc_handshake *) logic              src_req;     // backpressured toggle (CDC-013 safe)
  (* cdc_handshake *) logic [WIDTH-1:0]  src_payload; // held stable across req/ack (CDC-020 safe)
  logic              ack_in_src;          // ack synced into src domain

  // Destination-side
  logic              req_in_dst;          // req synced into dst domain
  logic              dst_req_d1;
  logic              dst_ack;

  // Synchronizers
  ip_cdc_sync #(.WIDTH(1), .STAGES(2)) u_sync_req (
    .clk(dst_clk), .rst_n(dst_rst_n), .d(src_req), .q(req_in_dst)
  );
  ip_cdc_sync #(.WIDTH(1), .STAGES(2)) u_sync_ack (
    .clk(src_clk), .rst_n(src_rst_n), .d(dst_ack),  .q(ack_in_src)
  );

  // Source FSM
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_req     <= 1'b0;
      src_payload <= '0;
    end else if (src_valid && src_ready) begin
      src_req     <= ~src_req;             // toggle on each accepted xfer
      src_payload <= src_data;
    end
  end
  assign src_ready = (src_req == ack_in_src);  // idle when no outstanding xfer

  // Destination edge detect on synced req
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      dst_req_d1 <= 1'b0;
      dst_ack    <= 1'b0;
      dst_valid  <= 1'b0;
      dst_data   <= '0;
    end else begin
      dst_req_d1 <= req_in_dst;
      if (req_in_dst != dst_req_d1) begin
        // payload is stable in src domain (held until ack returns)
        dst_data  <= src_payload;
        dst_valid <= 1'b1;
        dst_ack   <= req_in_dst;            // mirror src_req → ack
      end else begin
        dst_valid <= 1'b0;
      end
    end
  end

endmodule
