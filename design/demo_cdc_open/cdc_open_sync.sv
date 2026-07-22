// cdc_open_sync — portable N-flop level synchronizer.
//
// Two-flop (default) synchronizer for a single-bit signal — or several
// *independent* single-bit signals (WIDTH>1) — crossing into `clk`. The
// metastability-resolving flops carry only VENDOR-NEUTRAL attributes:
//
//   (* ASYNC_REG = "TRUE" *)  keep the chain physically adjacent and tell
//                             static timing the path is a synchronizer
//                             (honoured by Vivado; harmless elsewhere).
//   (* keep *)                never optimise / retime / merge the
//                             metastability flops away.
//
// No XPM macro, no UNISIM instantiation — the same RTL elaborates for
// ASIC and FPGA, under both Yosys (`synth_xilinx`) and Vivado. See
// ../../design/common/ip_cdc_sync.sv for the un-annotated structural twin.

module cdc_open_sync #(
  parameter int             WIDTH   = 1,
  parameter int             STAGES  = 2,
  parameter bit [WIDTH-1:0] RST_VAL = '0
)(
  input  logic             clk,
  input  logic             rst_n,   // sync-deassert reset, in `clk` domain
  input  logic [WIDTH-1:0] d,       // foreign-domain input
  output logic [WIDTH-1:0] q        // synced output, valid in `clk`
);

  (* ASYNC_REG = "TRUE", keep *)
  logic [WIDTH-1:0] sync_chain [STAGES];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < STAGES; i++) sync_chain[i] <= RST_VAL;
    end else begin
      sync_chain[0] <= d;
      for (int i = 1; i < STAGES; i++) sync_chain[i] <= sync_chain[i-1];
    end
  end

  assign q = sync_chain[STAGES-1];

endmodule
