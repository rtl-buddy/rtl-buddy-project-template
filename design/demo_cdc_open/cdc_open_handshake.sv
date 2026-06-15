// cdc_open_handshake — 4-phase request/ack vector CDC with held payload.
//
// A multi-bit payload crosses two clock domains via a req/ack handshake
// on single-bit control lines (each crossed through cdc_open_sync's
// ASYNC_REG 2-flop chain). The payload is held stable in the source
// domain for the whole handshake and captured by a single destination
// register, so wide vectors stay coherent without Gray coding. Structural
// twin of design/common/ip_cdc_handshake.sv.
//
// The synchronizer flops carry the vendor-neutral (* ASYNC_REG *)/
// (* keep *) attributes (inside cdc_open_sync). The (* cdc_handshake *)
// marks below are a CDC-linter hint that the req-toggle / held-payload /
// single-register-capture are protocol-safe — they are plain SV
// attributes, silently ignored by Yosys and Vivado (NOT a vendor macro),
// so portability is unaffected. rtl-buddy-cdc reads them to suppress the
// false positives a structure-only check would otherwise raise.

module cdc_open_handshake #(
  parameter int WIDTH = 16
)(
  // Source domain
  input  logic              src_clk,
  input  logic              src_rst_n,
  input  logic              src_valid,   // pulse to launch a transfer
  output logic              src_ready,   // 1 when ready to accept src_valid
  input  logic [WIDTH-1:0]  src_data,

  // Destination domain
  input  logic              dst_clk,
  input  logic              dst_rst_n,
  output logic              dst_valid,   // 1-cycle pulse per transfer (dst_clk)
  (* cdc_handshake *)
  output logic [WIDTH-1:0]  dst_data     // single-register capture
);

  (* cdc_handshake *) logic              src_req;     // backpressured toggle
  (* cdc_handshake *) logic [WIDTH-1:0]  src_payload; // held across req/ack
  logic                                  ack_in_src;
  logic                                  req_in_dst;
  logic                                  dst_req_d1;
  logic                                  dst_ack;

  // Control-line synchronizers (ASYNC_REG 2-flop inside cdc_open_sync).
  cdc_open_sync #(.WIDTH(1), .STAGES(2)) u_sync_req (
    .clk(dst_clk), .rst_n(dst_rst_n), .d(src_req), .q(req_in_dst)
  );
  cdc_open_sync #(.WIDTH(1), .STAGES(2)) u_sync_ack (
    .clk(src_clk), .rst_n(src_rst_n), .d(dst_ack),  .q(ack_in_src)
  );

  // Source FSM: toggle req and latch payload on each accepted transfer.
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_req     <= 1'b0;
      src_payload <= '0;
    end else if (src_valid && src_ready) begin
      src_req     <= ~src_req;
      src_payload <= src_data;
    end
  end
  assign src_ready = (src_req == ack_in_src);  // idle when no outstanding xfer

  // Destination: edge-detect synced req, capture held payload, mirror ack.
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      dst_req_d1 <= 1'b0;
      dst_ack    <= 1'b0;
      dst_valid  <= 1'b0;
      dst_data   <= '0;
    end else begin
      dst_req_d1 <= req_in_dst;
      if (req_in_dst != dst_req_d1) begin
        dst_data  <= src_payload;   // stable in src domain until ack returns
        dst_valid <= 1'b1;
        dst_ack   <= req_in_dst;
      end else begin
        dst_valid <= 1'b0;
      end
    end
  end

endmodule
