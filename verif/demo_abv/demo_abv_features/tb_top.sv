// demo_abv_features testbench — drives the DUT through reset + a few
// counting cycles and carries its own testbench-side SVA so the
// `assertions: true` knob in tests.yaml has something to compile in.
//
// Inline asserts in the design itself are wrapped in `ifdef FORMAL` so
// only `rb fpv` sees them; the SVA below is for `rb test` (#129).
`include "lvm_core.sv"

module tb_top;
  `LVM_INIT("demo_abv_features")
  localparam int MAX   = 7;
  localparam int WIDTH = $clog2(MAX + 1);

  logic              clk;
  logic              rst_n;
  logic              en;
  logic [WIDTH-1:0]  cnt;

  demo_abv_features #(.MAX(MAX), .WIDTH(WIDTH)) u_dut (
    .clk, .rst_n, .en, .cnt
  );

  // Testbench-side property: while enabled and out of reset, the
  // counter monotonically increases by 1 unless it has reached MAX.
  // The simulator compiles this in under `--assert`; the
  // `disable iff` gates the property during reset so the x-state
  // init cannot trigger a spurious failure. The `lint_off` waiver
  // mirrors the CDC-aware demos: the DUT uses rst_n async, and
  // sampling it synchronously inside an SVA disable-iff is
  // intentional for property writing.
  /* verilator lint_off SYNCASYNCNET */
  CNT_MONOTONE: assert property (
    @(posedge clk) disable iff (!rst_n)
      (en && cnt < MAX[WIDTH-1:0]) |=> (cnt == $past(cnt) + 1'b1)
  );
  /* verilator lint_on SYNCASYNCNET */

  // Labeled cover properties. `assertions: true` already injects
  // `--coverage-user`, so these are counted on every run of this test and
  // roll up into the `F:` (functional) column of the results table.
  //
  // The label is the part that matters: under `--machine`, rtl_buddy reports
  // each point by name with its hit count in
  // `payload.coverage.covers` — `{name, file, line, module, hits}` — so a
  // consumer can grade *which* points a run exercised rather than just how
  // many. See the "Per-cover-point results" section of the rtl_buddy
  // Coverage docs. Naming them after the intent, not the expression, is what
  // makes them mappable to verification-plan items.
  CNT_REACHED_MAX: cover property (@(posedge clk) rst_n && cnt == MAX[WIDTH-1:0]);
  CNT_ENABLED_LOW: cover property (@(posedge clk) rst_n && cnt == '0 && en);

  // Deliberately unreachable: `en` is never deasserted after reset release,
  // so this point stays at 0 hits. It is here to show that an uncovered
  // point is *reported* with `hits: 0` rather than omitted — a consumer
  // grading plan items needs to see the gap, not infer it from an absence.
  CNT_STALLED_WHILE_DISABLED: cover property (
    @(posedge clk) rst_n && !en && cnt == $past(cnt)
  );

  // Stimulus is driven on `negedge clk`, half a cycle before the DUT
  // and SVA both sample on the next posedge. Driving on `posedge clk`
  // with blocking `=` (the natural `initial`-script shape) puts the
  // stimulus writes and the DUT's `always_ff @(posedge clk)` input
  // sample in the same time slot's Active region — IEEE 1800 §4.7
  // leaves their relative order undefined, so a simulator that writes
  // stimulus first makes the DUT sample post-write values at the same
  // edge (counter increments at reset release instead of starting
  // next cycle). Driving on `negedge` settles inputs cleanly before
  // the next sample point and removes the race. Keep this; do not
  // refactor back to `posedge`.
  initial begin
    clk = 1'b0; rst_n = 1'b0; en = 1'b0;
    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    en    = 1'b1;
    repeat (MAX + 2) @(negedge clk);
    if (cnt !== MAX[WIDTH-1:0])
      `lvm_rpt_err(("expected cnt to saturate at MAX"));
    $display("PASS demo_abv_features counted up to %0d", cnt);
    $finish(0);
  end

  always #500ps clk = ~clk;
endmodule
