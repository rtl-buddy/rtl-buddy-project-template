// Concurrent SVA property module for demo_abv_features — exercises
// the slang-frontend FPV path (#134 vacuity covers).
//
// The local yosys verilog frontend does not parse `|->` / `|=>`; this
// file is read via `read_slang` instead. Bound into the DUT so the
// design source stays free of formal-only constructs.
//
// Two implications are deliberately included:
//
//  - `p_safe_count` — antecedent `en` is reachable under normal
//    operation; sby's vacuity cover pass should reach the antecedent
//    cover and report it as `ok`.
//  - `p_vacuous` — antecedent `1'b0` is never true. The vacuity pass
//    should flag this as `unreachable` and the rb fpv results table
//    should report `1/2 vacuous`.

module demo_abv_features_props_slang #(
  parameter int unsigned MAX   = 7,
  parameter int unsigned WIDTH = $clog2(MAX + 1)
)(
  input logic              clk,
  input logic              rst_n,
  input logic              en,
  input logic [WIDTH-1:0]  cnt
);

  // Reachable antecedent: `en` toggles in the testbench (and any
  // reasonable environment); the cover should be reached in one cycle.
  // Kept on a single line so rtl_buddy's vacuity-cover extractor
  // (regex-based, single-line today) picks up the antecedent.
  p_safe_count: assert property (@(posedge clk) disable iff (!rst_n) en |-> (cnt <= MAX[WIDTH-1:0]));

  // Vacuous antecedent: never true, so the assertion is vacuously
  // true. rb fpv should auto-derive a `cover (1'b0)` and report it as
  // unreached — flagging the property as vacuous in the results table.
  p_vacuous: assert property (@(posedge clk) disable iff (!rst_n) 1'b0 |-> (cnt == MAX[WIDTH-1:0]));

endmodule

// `bind` cannot pass the DUT's parameters into the bound module
// (they're not in scope at the bind site). Rely on the property
// module's defaults (MAX=7, matching the DUT's default) and the
// DUT's `cnt` port width — slang infers WIDTH at bind time.
bind demo_abv_features demo_abv_features_props_slang u_props_slang (
  .clk,
  .rst_n,
  .en,
  .cnt
);
