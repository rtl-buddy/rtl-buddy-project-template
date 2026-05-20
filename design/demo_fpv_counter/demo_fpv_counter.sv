// demo_fpv_counter — Saturating up-counter.
//
// Reference block for `rb fpv`. The accompanying property file under
// fpv/demo_fpv_counter/demo_fpv_counter_props.sv proves three things:
//   1. The counter never exceeds MAX (a safety property).
//   2. After reset, the counter is exactly 0 (reset property).
//   3. The counter can reach MAX (a cover property — sby with
//      mode=cover exercises this).

module demo_fpv_counter #(
  parameter int unsigned MAX   = 7,
  parameter int unsigned WIDTH = $clog2(MAX + 1)
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  output logic [WIDTH-1:0]  cnt
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= '0;
    end else if (en && cnt < MAX[WIDTH-1:0]) begin
      cnt <= cnt + 1'b1;
    end
  end

endmodule
