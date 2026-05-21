module tb_top;

  logic clk;
  logic rst_n;

  initial clk = 0;
  always #5ns clk = ~clk;

  axi_synth_bench i_dut (
    .clk_i  (clk),
    .rst_ni (rst_n)
  );

  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    repeat (20) @(posedge clk);
    $display("PASS synth_bench: all axi_synth_bench adapter variants elaborated");
    $finish(0);
  end

endmodule
