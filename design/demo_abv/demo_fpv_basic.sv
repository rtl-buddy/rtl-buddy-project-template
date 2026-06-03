// demo_fpv_basic — Saturating up-counter.
//
// Reference block for `rb fpv`. The accompanying property file under
// fpv/demo_abv/demo_fpv_basic/demo_fpv_basic_props.sv proves three things:
//   1. The counter never exceeds MAX (a safety property).
//   2. After reset, the counter is exactly 0 (reset property).
//   3. The counter can reach MAX (a cover property — sby with
//      mode=cover exercises this).

module demo_fpv_basic #(
  // MAX must NOT be 2**WIDTH-1: if it fills the counter's bit width
  // exactly, the safety assertion `cnt <= MAX` is vacuously true (cnt
  // physically can't exceed it) and nothing — not a bug, not a mutation
  // — can falsify it. With MAX=5 and WIDTH=3, cnt spans 0..7, leaving
  // 6/7 as representable overflow states the proof can actually catch.
  parameter int unsigned MAX   = 5,
  parameter int unsigned WIDTH = $clog2(MAX + 1)
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  // Power-up value. Models the counter starting in its reset state,
  // which the BMC proof needs as a defined initial condition (the
  // async reset alone doesn't pin the t=0 state in formal). This is
  // ordinary RTL — no formal-only constructs leak into the design.
  output logic [WIDTH-1:0]  cnt = '0
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= '0;
    end else if (en && cnt < MAX[WIDTH-1:0]) begin
      cnt <= cnt + 1'b1;
    end
  end

endmodule
