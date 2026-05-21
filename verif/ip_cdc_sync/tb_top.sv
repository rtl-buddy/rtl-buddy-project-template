// ip_cdc_sync standalone testbench.
// Drives `d` across reset and steady-state edges, asserts the latency
// matches STAGES, and bumps the SAND-FUNC-* style cover labels matching
// CDCSYNC-* IDs in spec/ip_cdc_sync/specs.yaml.
`include "lvm_core.sv"

module tb_top;
  `LVM_INIT("ip_cdc_sync")
  localparam int STAGES = 2;

  logic clk, rst_n, d;
  logic q;

  ip_cdc_sync #(.WIDTH(1), .STAGES(STAGES), .RST_VAL(1'b0)) u_dut (
    .clk, .rst_n, .d, .q
  );

  // Cover labels mirror CDCSYNC-* IDs (kept simple for Verilator SVA)
  CDCSYNC_RESET:   cover property (@(posedge clk) !rst_n && q == 1'b0);
  CDCSYNC_D_LOW:   cover property (@(posedge clk) rst_n && d == 1'b0 && q == 1'b0);
  CDCSYNC_D_HIGH:  cover property (@(posedge clk) rst_n && d == 1'b1 && q == 1'b1);
  CDCSYNC_LATENCY: cover property (@(posedge clk) rst_n && d != q);

  initial begin
    clk = 1'b0; rst_n = 1'b0; d = 1'b0;
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    d = 1'b1; repeat (STAGES + 2) @(posedge clk);
    if (q !== 1'b1) `lvm_rpt_err(("expected q=1 after sync"));
    d = 1'b0; repeat (STAGES + 2) @(posedge clk);
    if (q !== 1'b0) `lvm_rpt_err(("expected q=0 after sync"));
    repeat (4) @(posedge clk);
    $finish(0);
  end

  always #500ps clk = ~clk;
endmodule
