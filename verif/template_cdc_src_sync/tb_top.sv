// vim: set ts=2 sw=2 et :
//
// Testbench for template_cdc_src_sync_top. Drives ck_a + rst_n,
// toggles d_in, and asserts that data eventually appears at the C0
// and C1 outputs (the chain propagates through four flop stages on
// divided clocks, so we wait many cycles before checking).
`include "lvm_core.sv"

`define TB_CLK_PERIOD 500ps

class EndHook implements LvmPkg::TestEndHook;
  virtual function void end_of_test(LvmPkg::TestCore c);
    begin
      $display("custom end_of_test()");
      $display("nerr=%d", c.nerr);
    end
  endfunction
endclass

module tb_top;

  `LVM_INIT("test_template_cdc_src_sync")

  logic ck_a;
  logic rst_n;
  logic d_in;
  logic q_out_c0, q_out_c1;

  integer test_cycles = 200;

  template_cdc_src_sync_top i_dut (
    .ck_a     (ck_a),
    .rst_n    (rst_n),
    .d_in     (d_in),
    .q_out_c0 (q_out_c0),
    .q_out_c1 (q_out_c1)
  );

  EndHook eh;

  initial begin:main
    eh = new();
    tc.add_test_end_hook(eh);

    ck_a  = 1'b0;
    rst_n = 1'b0;
    d_in  = 1'b0;

    if ($test$plusargs("test_cycles")) begin
      $value$plusargs("test_cycles=%d", test_cycles);
    end

    `lvm_rpt_inf(("test starting"));

    // Hold reset long enough for every divider stage to clear.
    repeat (8) @(negedge ck_a);
    rst_n = 1'b1;
    `lvm_rpt_inf(("reset deasserted"));

    // Drive d_in high and let the chain propagate. The c-stage runs
    // on ck_a / 4, so 32 ck_a cycles is plenty for the bit to walk
    // through both branches.
    d_in = 1'b1;
    repeat (32) @(negedge ck_a);

    if (q_out_c0 !== 1'b1) begin
      `lvm_rpt_err(("q_out_c0 did not propagate to 1 (got %b)", q_out_c0));
    end
    if (q_out_c1 !== 1'b1) begin
      `lvm_rpt_err(("q_out_c1 did not propagate to 1 (got %b)", q_out_c1));
    end

    // Drive d_in low, confirm the chain returns to 0.
    d_in = 1'b0;
    repeat (32) @(negedge ck_a);

    if (q_out_c0 !== 1'b0) begin
      `lvm_rpt_err(("q_out_c0 did not propagate to 0 (got %b)", q_out_c0));
    end
    if (q_out_c1 !== 1'b0) begin
      `lvm_rpt_err(("q_out_c1 did not propagate to 0 (got %b)", q_out_c1));
    end

    repeat (test_cycles) @(negedge ck_a);

    $finish(0);
  end:main

  always #`TB_CLK_PERIOD ck_a = ~ck_a;

endmodule
