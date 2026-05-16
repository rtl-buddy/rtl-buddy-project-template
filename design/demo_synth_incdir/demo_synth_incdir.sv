// vim: set ts=2 sw=2 et :
//
// Minimal synthesizable DUT used to reproduce rtl_buddy issue #69.
//
// The design itself is intentionally trivial — a registered W-bit
// adder — so that the only interesting thing about it is the
// `\`include` directive, which forces the filelist consumer to honor
// the `+incdir+.` entry in `test_modules.f`.

`include "demo_synth_incdir_defs.svh"

module demo_synth_incdir (
  input  logic                              clk,
  input  logic                              rst,
  input  logic [`DEMO_SYNTH_INCDIR_W-1:0]   a,
  input  logic [`DEMO_SYNTH_INCDIR_W-1:0]   b,
  output logic [`DEMO_SYNTH_INCDIR_W-1:0]   y
);

  always_ff @(posedge clk) begin
    if (rst) y <= '0;
    else     y <= a + b;
  end

endmodule
