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
// the noninductive and inductive checkers (the ones that make the
// "passes BMC, fails prove" boundary visible).

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
