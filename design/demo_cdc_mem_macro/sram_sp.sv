// Single-clock synchronous SRAM macro — the canonical blackbox target:
// a hard IP whose (large) memory array you stub out for CDC scaling.
// One clock (clk), registered read/write. No CDC of its own.
module sram_sp #(parameter AW = 8, DW = 32) (
    input  logic          clk,
    input  logic          ce,
    input  logic          we,
    input  logic [AW-1:0] addr,
    input  logic [DW-1:0] wdata,
    output logic [DW-1:0] rdata
);
  logic [DW-1:0] mem [(1<<AW)];
  always_ff @(posedge clk) begin
    if (ce) begin
      if (we) mem[addr] <= wdata;
      rdata <= mem[addr];
    end
  end
endmodule
