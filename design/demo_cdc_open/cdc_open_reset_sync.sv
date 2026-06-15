// cdc_open_reset_sync — asynchronous-assert, synchronous-deassert reset
// synchronizer. An asynchronous reset asserts immediately but deasserts
// in step with `clk`, so downstream flops leave reset on a clean edge and
// never sample a recovery/removal violation. Same vendor-neutral
// (* ASYNC_REG *)/(* keep *) annotation as cdc_open_sync — no XPM, no
// UNISIM, portable across ASIC/FPGA and Yosys/Vivado.

module cdc_open_reset_sync #(
  parameter int STAGES = 2
)(
  input  logic clk,
  input  logic arst_n,   // asynchronous reset, active-low
  output logic rst_n     // synchronized reset, active-low, in `clk` domain
);

  (* ASYNC_REG = "TRUE", keep *)
  logic [STAGES-1:0] rst_chain;

  always_ff @(posedge clk or negedge arst_n) begin
    if (!arst_n) rst_chain <= '0;
    else         rst_chain <= {rst_chain[STAGES-2:0], 1'b1};
  end

  assign rst_n = rst_chain[STAGES-1];

endmodule
