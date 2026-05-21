// SVA-style properties for demo_fpv_counter, used by `rb fpv`.
//
// We bind the checker into the DUT so the design RTL stays free of
// formal-only constructs. Assertions are written as immediate
// `assert` / `cover` inside `always @(posedge clk)` blocks because
// that is the subset Yosys's native Verilog frontend supports today.
// Broader SVA (`property`, sequence operators, `default clocking`)
// will land alongside the slang frontend tracked in rtl_buddy issue
// #88.

module demo_fpv_counter_props #(
  parameter int unsigned MAX   = 7,
  parameter int unsigned WIDTH = $clog2(MAX + 1)
)(
  input logic              clk,
  input logic              rst_n,
  input logic [WIDTH-1:0]  cnt
);

  // Safety: counter must never exceed MAX once reset is released.
  always @(posedge clk) begin
    if (rst_n) begin
      assert (cnt <= MAX[WIDTH-1:0]);
    end
  end

  // Cover: a trace exists where counter reaches MAX. Surfaces as an
  // engine "cover reached" result under `mode: cover` in fpv.yaml.
  always @(posedge clk) begin
    cover (cnt == MAX[WIDTH-1:0]);
  end

endmodule

// Bind the property module into the design hierarchy.
bind demo_fpv_counter demo_fpv_counter_props #(
  .MAX  (MAX),
  .WIDTH(WIDTH)
) u_props (
  .clk  (clk),
  .rst_n(rst_n),
  .cnt  (cnt)
);
