// Teaching checkers for demo_abv_induction.
//
// Each module wraps the wrapping mod-5 counter and asserts a single
// safety property. They are split into separate top modules so each
// `rb fpv` verification can target exactly one property via `top:` —
// the native yosys verilog frontend elaborates from the chosen top and
// prunes the others (`hierarchy -top`), so no `bind`/slang is needed.
//
// Immediate assertions live under `` `ifdef FORMAL `` for consistency
// with the other demos; only `rb fpv` (yosys `read -formal`) defines
// the macro. These modules are never simulated.
//
// The three properties are all *true* of the counter, yet they behave
// differently under induction (`mode: prove`):
//
//   cnt != 6   true AND inductive   — nothing transitions to 6
//                                     (5 wraps to 0), so prove succeeds
//   cnt != 26  true but NOT inductive — the unreachable predecessor
//                                       cnt==25 steps to 26, so the
//                                       induction step finds a spurious
//                                       counterexample: prove FAILS even
//                                       though BMC passes
//   cnt <= 5   true AND inductive   — the reachable set {0..5} is closed
//                                     under the transition relation; the
//                                     recommended way to write the intent
//
// `demo_abv_induction_chk_unreachable` covers the `cnt != 6` case and is
// kept for reference / README discussion; the shipped fpv.yaml drives
// the noninductive, inductive, and companion checkers (the ones that
// make the "passes BMC, fails prove" boundary — and the way to push it
// back — visible).
//
// `demo_abv_induction_chk_companion` shows a fourth lesson: two
// assertions can be inductive *together* even when one is not inductive
// alone. Asserting `cnt != 6` alongside `cnt != 26` makes the pair prove
// at the same `depth: 20` where `cnt != 26` alone fails — the companion
// `cnt != 6` prunes the one CTI ramp into 26 (which must pass through 6).

module demo_abv_induction_chk_unreachable (input logic clk);
  logic [9:0] cnt;
  demo_abv_induction dut (.clk, .cnt);
  `ifdef FORMAL
  // Unreachable AND inductive: passes both BMC and prove.
  always @(*) assert (cnt != 10'd6);
  `endif
endmodule

module demo_abv_induction_chk_noninductive (input logic clk);
  logic [9:0] cnt;
  demo_abv_induction dut (.clk, .cnt);
  `ifdef FORMAL
  // Unreachable but NOT inductive: passes BMC, fails prove. This is the
  // exact boundary where the induction hypothesis breaks down — an
  // arbitrary (unreachable) state cnt==25 transitions to 26.
  always @(*) assert (cnt != 10'd26);
  `endif
endmodule

module demo_abv_induction_chk_inductive (input logic clk);
  logic [9:0] cnt;
  demo_abv_induction dut (.clk, .cnt);
  `ifdef FORMAL
  // The same intent as the two unreachable-value asserts above, but
  // expressed as an inductive invariant over the reachable set {0..5}.
  // Closed under the transition relation, so prove succeeds. Preferred
  // style: it constrains the inductive step instead of poking at a
  // single unreachable value.
  always @(*) assert (cnt <= 10'd5);
  `endif
endmodule

module demo_abv_induction_chk_companion (input logic clk);
  logic [9:0] cnt;
  demo_abv_induction dut (.clk, .cnt);
  `ifdef FORMAL
  // Two assertions that are inductive *together* though one is not
  // inductive alone. `cnt != 26` by itself fails prove at depth 20
  // (the CTI ramp 6->...->26 fits in the window). But every such ramp
  // must pass through cnt==6, and asserting `cnt != 6` makes that value
  // part of the induction hypothesis at every prior state — so no CTI
  // into 26 survives, and BOTH properties prove at the same depth 20.
  // `cnt != 6` is inductive on its own (6 has no predecessor); here it
  // doubles as the companion that prunes the bad predecessor of 26.
  always @(*) assert (cnt != 10'd6);
  always @(*) assert (cnt != 10'd26);
  `endif
endmodule
