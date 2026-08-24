// A design with a hard macro in it, and enough standard-cell logic around the
// macro for an area figure and a timing path to mean something.
//
// The point of the demo is the boundary: demo_hard_macro is a blackbox in RTL
// and a real master to the backend, which reads its LEF and Liberty. See
// synth/demo_synth_macro/README.md.
module demo_synth_macro_top #(
  parameter int WIDTH = 8
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             en,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);

  logic [WIDTH-1:0] macro_q;

  demo_hard_macro i_macro (
    .clk (clk),
    .en  (en),
    .d   (d),
    .q   (macro_q)
  );

  // One flop stage on the macro output, so macro q -> flop D is a real path and
  // the standard-cell count is not zero.
  logic [WIDTH-1:0] cap_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cap_q <= '0;
    else        cap_q <= macro_q ^ {macro_q[WIDTH-2:0], 1'b0};
  end

  assign q = cap_q;

endmodule
