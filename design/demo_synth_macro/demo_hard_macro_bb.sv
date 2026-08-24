// Blackbox declaration for demo_hard_macro.
//
// Ports only, no body. The RTL frontend needs a module to bind instances to;
// everything else about this block comes from its physical and timing views in
// macro/: demo_hard_macro.lef for the extent, demo_hard_macro.lib for the arcs.
// Anything written here would be a second, divergent source of truth.
(* blackbox *)
module demo_hard_macro (
  input  wire       clk,
  input  wire       en,
  input  wire [7:0] d,
  output wire [7:0] q
);
endmodule
