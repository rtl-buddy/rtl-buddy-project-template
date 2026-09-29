// Blackbox declaration for demo_hard_macro.
//
// Ports only, no body. The RTL frontend needs a module to bind instances to;
// everything else about this block comes from the abstract its hardening run
// published (pnr/demo_synth_macro/pnr.yaml): the LEF for the extent, the
// Liberty timing model for the arcs. The top reads this file, never
// demo_hard_macro.sv, so to the top the macro is that abstract and nothing
// else. Anything written here would be a second, divergent source of truth.
(* blackbox *)
module demo_hard_macro (
  input  wire       clk,
  input  wire       en,
  input  wire [7:0] d,
  output wire [7:0] q
);
endmodule
