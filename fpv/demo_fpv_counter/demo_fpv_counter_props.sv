// SVA-style properties for demo_fpv_counter, used by `rb fpv`.
//
// We bind the checker into the DUT so the design RTL stays free of
// formal-only constructs. The bind is what makes this checker reach
// the design, and `bind` is only elaborated by the slang frontend —
// so fpv.yaml sets `frontend: slang` (the native Yosys verilog
// frontend silently drops bind directives, which would leave the proof
// with no assertions at all). See tools/yosys-slang/SETUP_OSX.md for
// building the plugin that `cfg-fpv-tools.opts.plugin-path` points at.

module demo_fpv_counter_props #(
  // Defaults mirror the DUT (see demo_fpv_counter.sv on why MAX != 2**WIDTH-1);
  // the bind below overrides both with the DUT's actual parameters.
  parameter int unsigned MAX   = 5,
  parameter int unsigned WIDTH = $clog2(MAX + 1)
)(
  input logic              clk,
  input logic              rst_n,
  input logic [WIDTH-1:0]  cnt
);

  // The defined initial state comes from the DUT's `cnt = '0` power-up
  // value (see demo_fpv_counter.sv), so no reset assumption is needed
  // here — the BMC trace starts from cnt==0 and the property must hold
  // for every reachable state thereafter.

  // Safety: counter must never exceed MAX once reset is released.
  always @(posedge clk) begin
    if (rst_n) begin
      assert (cnt <= MAX[WIDTH-1:0]);
    end
  end

  // Cover: a trace exists where counter reaches MAX. Surfaces as an
  // engine "cover reached" result under `mode: cover` in fpv.yaml.
  always @(posedge clk) begin
    cover (cnt == MAX[WIDTH-1:0]);
  end

endmodule

// Bind the property module into the design hierarchy.
bind demo_fpv_counter demo_fpv_counter_props #(
  .MAX  (MAX),
  .WIDTH(WIDTH)
) u_props (
  .clk  (clk),
  .rst_n(rst_n),
  .cnt  (cnt)
);
