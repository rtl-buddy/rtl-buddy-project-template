// Minimal procedural testbench for the icarus_smoke counter.
// No classes / SVA / covergroups — runs on both Verilator and Icarus.
module tb_counter;

  logic       clk;
  logic       rst_n;
  logic       enable;
  logic [3:0] count;
  int         errors;

  initial begin
    clk    = 0;
    rst_n  = 0;
    enable = 0;
    errors = 0;
  end

  counter #(.WIDTH(4)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .count(count)
  );

  // 10 ns clock
  always #5 clk = ~clk;

  initial begin
    // Reset
    #3 rst_n = 0;
    #20 rst_n = 1;
    if (count !== 4'h0) begin
      $display("ERR: count after reset = %0h, expected 0", count);
      errors = errors + 1;
    end

    // Count 10 cycles with enable high
    enable = 1;
    repeat (10) @(posedge clk);
    #1;
    if (count !== 4'hA) begin
      $display("ERR: count after 10 cycles = %0h, expected A", count);
      errors = errors + 1;
    end

    // Disable: counter should hold
    enable = 0;
    repeat (5) @(posedge clk);
    #1;
    if (count !== 4'hA) begin
      $display("ERR: count after disable hold = %0h, expected A", count);
      errors = errors + 1;
    end

    if (errors == 0)
      $display("PASS icarus_smoke basic");
    else
      $display("FAIL icarus_smoke basic (%0d errors)", errors);
    $finish;
  end

  // Coarse timeout so a stuck sim still emits FAIL.
  initial begin
    #10000;
    $display("FAIL icarus_smoke basic");
    $display("ERR: timeout reached");
    $finish;
  end

endmodule
