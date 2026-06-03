// demo_abv_features — small saturating counter authored to exercise
// rtl_buddy's Assertion-Based Verification surface end-to-end:
//
//   * #129 — SVA in `rb test` via Verilator `--assert` (testbench-side
//     SVA — see verif/demo_abv_features/tb_top.sv)
//   * #134 — auto-derived vacuity covers for `|->` properties
//     (via the slang-fronted `rb fpv` path — see
//     fpv/demo_abv_features/demo_abv_features_props_slang.sv)
//   * #135 — dead-assume detection (structural)
//   * #136 — cone-of-influence (COI) coverage
//
// Inline `assert` / `assume` statements below are wrapped in
// ``ifdef FORMAL`` so only `rb fpv` sees them (yosys's `read -formal`
// defines that macro; Verilator does not). Verilator-only constructs
// like `assume` would otherwise fail at t=0 on x-driven inputs.

module demo_abv_features #(
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

  // --- Formal-only properties ------------------------------------------------
  // Visible to yosys (under `read -formal`) but invisible to Verilator
  // simulation. Keeps the rb test SVA demo (#129) decoupled from the
  // rb fpv coverage demos (#134/#135/#136).
  `ifdef FORMAL
  // Safety: while reset is asserted the counter is held at zero.
  //
  // The DUT drives rst_n as an *asynchronous* reset (see the
  // `always_ff @(posedge clk or negedge rst_n)` above), so the
  // property is written combinationally (`always @(*)`) rather than
  // sampled on the clock. It must hold the instant rst_n falls —
  // matching the RTL's reset semantics rather than a clocked
  // approximation that only checks at the next posedge. Authoring the
  // assertion combinationally also means rst_n is no longer sampled
  // synchronously, so the SYNCASYNCNET waiver the clocked form needed
  // is gone.
  //
  // Cheapest non-trivial property — gives the COI walk something
  // non-vacuous to land on.
  always @(*) begin
    if (!rst_n) begin
      assert (cnt == '0);
    end
  end

  // Intentionally dead assumption: `en || !en` is a tautology and
  // doesn't constrain anything. The COI pass should report it as a
  // dead assume (#135) — it isn't in the assertion above's cone of
  // influence.
  always @(posedge clk) begin
    assume (en || !en);
  end
  `endif

endmodule
