// ip_async_fifo — Gray-code dual-clock asynchronous FIFO.
//
// Slim demonstrator FIFO with gray-coded read/write pointers crossing
// the clock boundary through 2-FF synchronizers. DEPTH must be a power
// of 2. Independent active-low resets per domain.
//
// See spec/ip_async_fifo/README.md.

module ip_async_fifo #(
  parameter int DEPTH  = 8,
  parameter int DATA_W = 8
)(
  // Write side (wclk domain)
  input  logic              wclk,
  input  logic              wrst_n,
  input  logic              wr_en,
  input  logic [DATA_W-1:0] wr_data,
  output logic              wr_full,

  // Read side (rclk domain)
  input  logic              rclk,
  input  logic              rrst_n,
  input  logic              rd_en,
  output logic [DATA_W-1:0] rd_data,
  output logic              rd_empty
);

  localparam int PTR_W = $clog2(DEPTH) + 1;   // +1 MSB to disambiguate full/empty
  localparam int ADDR_W = $clog2(DEPTH);

  // ── Storage (simple 2-port RAM behaviour)
  logic [DATA_W-1:0] mem [DEPTH];

  // ── Write side
  logic [PTR_W-1:0] wptr_bin, wptr_gray;
  logic [PTR_W-1:0] wptr_bin_next, wptr_gray_next;
  logic [PTR_W-1:0] rptr_gray_in_w;

  assign wptr_bin_next  = wptr_bin + 1'b1;
  assign wptr_gray_next = wptr_bin_next ^ (wptr_bin_next >> 1);

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wptr_bin  <= '0;
      wptr_gray <= '0;
    end else if (wr_en && !wr_full) begin
      mem[wptr_bin[ADDR_W-1:0]] <= wr_data;
      wptr_bin  <= wptr_bin_next;
      wptr_gray <= wptr_gray_next;
    end
  end

  ip_cdc_sync #(.WIDTH(PTR_W), .STAGES(2)) u_sync_rptr (
    .clk(wclk), .rst_n(wrst_n), .d(rptr_gray), .q(rptr_gray_in_w)
  );

  // Full when next-write-gray equals read-pointer-gray with top two bits flipped
  assign wr_full = (wptr_gray_next ==
                    {~rptr_gray_in_w[PTR_W-1:PTR_W-2], rptr_gray_in_w[PTR_W-3:0]});

  // ── Read side
  logic [PTR_W-1:0] rptr_bin, rptr_gray;
  logic [PTR_W-1:0] rptr_bin_next, rptr_gray_next;
  logic [PTR_W-1:0] wptr_gray_in_r;

  assign rptr_bin_next  = rptr_bin + 1'b1;
  assign rptr_gray_next = rptr_bin_next ^ (rptr_bin_next >> 1);

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr_bin  <= '0;
      rptr_gray <= '0;
    end else if (rd_en && !rd_empty) begin
      rptr_bin  <= rptr_bin_next;
      rptr_gray <= rptr_gray_next;
    end
  end

  ip_cdc_sync #(.WIDTH(PTR_W), .STAGES(2)) u_sync_wptr (
    .clk(rclk), .rst_n(rrst_n), .d(wptr_gray), .q(wptr_gray_in_r)
  );

  assign rd_empty = (rptr_gray == wptr_gray_in_r);
  assign rd_data  = mem[rptr_bin[ADDR_W-1:0]];

endmodule
