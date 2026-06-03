// demo_abv_induction — a tiny wrapping counter authored to make the
// BMC-vs-induction distinction observable end-to-end through `rb fpv`.
//
// This is a *formal-only* teaching block: it is never simulated, so it
// carries no reset port and relies on a power-on `initial` value to pin
// the formal base case. The companion checkers in
// `demo_abv_induction_props.sv` assert three properties that behave
// differently under `mode: bmc` vs `mode: prove` — see this block's
// README and `fpv/demo_abv_induction/fpv.yaml`.
//
// The counter walks 0,1,2,3,4,5,0,1,... so its reachable state set is
// exactly {0..5}. Every value above 5 is unreachable — but, as the
// checkers show, "unreachable" and "inductive" are not the same thing.

module demo_abv_induction (
  input  logic       clk,
  output logic [9:0] cnt
);

  // Power-on value. In the formal model this pins the BMC base case to
  // a reachable state (cnt==0); without it cnt would be free at t=0 and
  // even `cnt != 26` would have a trivial t=0 counterexample, masking
  // the actual induction lesson.
  initial cnt = 10'd0;

  // Wrapping counter: increments to 5, then wraps to 0.
  always_ff @(posedge clk) begin
    if (cnt == 10'd5) begin
      cnt <= 10'd0;
    end else begin
      cnt <= cnt + 10'd1;
    end
  end

endmodule
