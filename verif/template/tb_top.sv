// vim: set ts=2 sw=2 et :
//
// Example testbench for this template project.
//
// lvm_core contains Lightweight Verification Methodolgy 
// core test framework, report handling, error counting, pass/fail
`include "lvm_core.sv"

`define TB_CLK_PERIOD 500ps

// Any end_of_test code should be called via the EndHook class interface
//
// See this example on how to use EndHooks to 
// implement end_of_test notifications
class EndHook implements LvmPkg::TestEndHook;
  virtual function void end_of_test(LvmPkg::TestCore c);
    begin
    $display("custom end_of_test()");
    $display("nerr=%d", c.nerr);
    end
  endfunction
endclass

module tb_top;

  `LVM_INIT("test_template_top")

  logic clk;
  logic rst;

  localparam W = 4;
  logic[W-1:0] a;
  logic[W-1:0] b;
  logic[W-1:0] z;

  integer test_cycles = 20;

  // instantiate DUT
  template_top #( 
      .WIDTH(4) 
    ) i_dut (
      .clk,
      .rst,
      .a,
      .b,
      .z
    );

  //end-of-test hook
  EndHook eh;

  initial begin:main
  eh = new();
  tc.add_test_end_hook(eh);
  
  clk = '0;
  rst = '1;
  a   = '0;
  b   = '0;

  `lvm_rpt_inf(("test starting"));

  if ($test$plusargs("a")) begin
    $value$plusargs("a=%d", a);
    $display("plusargs set a=%d", a);
    end
  if ($test$plusargs("b")) begin
    $value$plusargs("b=%d", b);
    $display("plusargs set b=%d", b);
    end
  if ($test$plusargs("flag")) begin 
    $display("plusargs set flag");
    end
  if ($test$plusargs("test_cycles")) begin
    $value$plusargs("test_cycles=%d", test_cycles);
    end

  repeat (4) @(negedge clk);
  `lvm_rpt_inf(("reset deasserted"));
  rst = '0;

  repeat (test_cycles) begin
    `lvm_rpt_inf(("b=%d", b));
    b = b + 1;
    @(negedge clk);
  end

  $finish(0);
  end:main

  // DO NOT USE final begin end in tb_top module
  // use the TestHook methodology instead to ensure
  // that your cleanup tasks are done before the final PASS/FAIL
  // message is produced for the regression infrastructure

  always #`TB_CLK_PERIOD clk = ~clk;

endmodule
