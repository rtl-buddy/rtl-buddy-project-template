// demo_hard_macro: the block demo_synth_macro_top instances as a hard macro.
//
// This is the RTL the macro is *hardened* from: `rb pnr` places and routes it
// on sky130hd with `harden: true` and publishes its abstract (LEF, Liberty
// timing model, GDS). The top never compiles this file -- its filelist reads
// demo_hard_macro_bb.sv, the port-only blackbox -- so to the top the block is
// its abstract and nothing else. See synth/demo_synth_macro/README.md.
//
// A short registered pipeline, so the abstract has a real clk -> q arc and a
// real setup check on d, and enough cells to be worth hardening. `d` and `q`
// stay 8 bits wide: the bussed ports are what the demo's regression needs.
module demo_hard_macro (
  input  logic       clk,
  input  logic       en,
  input  logic [7:0] d,
  output logic [7:0] q
);

  logic [7:0] s0, s1, s2, s3;

  always_ff @(posedge clk) begin
    if (en) begin
      s0 <= d;
      s1 <= s0 ^ {s0[6:0], s0[7]};
      s2 <= s1 + s0;
      s3 <= s2 ^ {s1[3:0], s1[7:4]};
    end
  end

  assign q = s3;

endmodule
