// cdc_open_gray_bus — multi-bit value crossing via Gray code.
//
// A binary counter advances in the source domain. Only its Gray encoding
// (exactly one bit flips per increment) is allowed to cross, so the
// multi-bit vector synchronizer can never latch a half-settled multi-bit
// transition: at worst it captures the old or the new code, never a
// mixture. The destination decodes Gray back to binary. This is the
// portable, attribute-only alternative to a vendor async-FIFO macro for
// monotonic values (counters, pointers).
//
// The vector crosses through cdc_open_sync, which carries the
// vendor-neutral (* ASYNC_REG *)/(* keep *) flops.

module cdc_open_gray_bus #(
  parameter int WIDTH = 8
)(
  input  logic             src_clk,
  input  logic             src_rst_n,
  input  logic             src_incr,
  output logic [WIDTH-1:0] src_count,   // source-domain binary count

  input  logic             dst_clk,
  input  logic             dst_rst_n,
  output logic [WIDTH-1:0] dst_count    // value observed in the dst domain
);

  logic [WIDTH-1:0] bin_q;
  logic [WIDTH-1:0] gray_q;
  logic [WIDTH-1:0] gray_dst;
  logic [WIDTH-1:0] bin_next;

  assign bin_next = bin_q + 1'b1;

  // Source: binary counter + registered Gray encoding.
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      bin_q  <= '0;
      gray_q <= '0;
    end else if (src_incr) begin
      bin_q  <= bin_next;
      gray_q <= bin_next ^ (bin_next >> 1);
    end
  end
  assign src_count = bin_q;

  // The Gray vector crosses through a 2-flop synchronizer.
  cdc_open_sync #(.WIDTH(WIDTH), .STAGES(2)) u_gray_sync (
    .clk   (dst_clk),
    .rst_n (dst_rst_n),
    .d     (gray_q),
    .q     (gray_dst)
  );

  // Destination: Gray -> binary decode.
  always_comb begin
    dst_count[WIDTH-1] = gray_dst[WIDTH-1];
    for (int i = WIDTH-2; i >= 0; i--)
      dst_count[i] = dst_count[i+1] ^ gray_dst[i];
  end

endmodule
