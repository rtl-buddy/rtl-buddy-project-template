// ip_async_fifo standalone testbench: dual-clock smoke + ordering check.
`include "lvm_core.sv"

module tb_top;
  `LVM_INIT("ip_async_fifo")
  localparam int DEPTH  = 8;
  localparam int DATA_W = 8;

  logic wclk, rclk, wrst_n, rrst_n;
  logic wr_en, rd_en;
  logic [DATA_W-1:0] wr_data, rd_data;
  logic wr_full, rd_empty;

  ip_async_fifo #(.DEPTH(DEPTH), .DATA_W(DATA_W)) u_dut (
    .wclk, .wrst_n, .wr_en, .wr_data, .wr_full,
    .rclk, .rrst_n, .rd_en, .rd_data, .rd_empty
  );

  bit [DATA_W-1:0] expected[$];
  // `popped` / `mismatches` are incremented from the always_ff below, so they
  // are deliberately left un-initialised: they are 2-state and start at 0, and
  // both ways of saying so explicitly are rejected by Verilator 5.050 —
  // assigning them in the initial block below is MULTIDRIVEN against the
  // always_ff writes, a declaration initialiser is PROCASSINIT against them.
  int unsigned    pushed;
  int unsigned    popped;
  int unsigned    mismatches;
  bit             active;

  // Cover labels
  AFIFO_PUSH:  cover property (@(posedge wclk) wr_en && !wr_full);
  AFIFO_POP:   cover property (@(posedge rclk) rd_en && !rd_empty);
  AFIFO_FULL:  cover property (@(posedge wclk) wr_full);
  AFIFO_EMPTY: cover property (@(posedge rclk) rd_empty && popped > 0);
  AFIFO_ORDER: cover property (@(posedge rclk) active && rd_en && !rd_empty &&
                                                expected.size() != 0 && rd_data == expected[0]);

  // Read-side scoreboard
  always_ff @(posedge rclk) begin
    if (active && rd_en && !rd_empty) begin
      bit [DATA_W-1:0] e;
      if (expected.size() == 0) begin
        mismatches <= mismatches + 1;
        `lvm_rpt_err(("pop with empty expected; rd_data=%h", rd_data));
      end else begin
        e = expected.pop_front();
        if (rd_data !== e) begin
          mismatches <= mismatches + 1;
          `lvm_rpt_err(("pop mismatch rd=%h ref=%h", rd_data, e));
        end
      end
      popped <= popped + 1;
    end
  end

  task automatic do_push(input bit [DATA_W-1:0] d);
    @(negedge wclk);
    while (wr_full) @(negedge wclk);
    wr_data = d;
    wr_en   = 1'b1;
    expected.push_back(d);
    pushed += 1;
    @(negedge wclk);
    wr_en = 1'b0;
  endtask

  task automatic do_pop();
    @(negedge rclk);
    while (rd_empty) @(negedge rclk);
    rd_en = 1'b1;
    @(negedge rclk);
    rd_en = 1'b0;
  endtask

  initial begin
    pushed = 0; active = 1'b0;
    wclk = 1'b0; rclk = 1'b0;
    wrst_n = 1'b0; rrst_n = 1'b0;
    wr_en = 1'b0; rd_en = 1'b0; wr_data = '0;
    repeat (8) @(posedge rclk);
    wrst_n = 1'b1; rrst_n = 1'b1;
    repeat (4) @(posedge rclk);
    active = 1'b1;

    // Fill until full → covers AFIFO_FULL
    fork
      begin
        for (int i = 0; i < DEPTH + 4; i++) do_push(8'(8'hA0 + i));
      end
      begin
        // Drain after a delay — covers AFIFO_EMPTY at the end
        repeat (DEPTH * 4) @(posedge rclk);
        for (int i = 0; i < DEPTH + 4; i++) do_pop();
      end
    join

    // Wait for any in-flight pop scoreboard updates
    repeat (10) @(posedge rclk);

    if (pushed != DEPTH + 4) `lvm_rpt_err(("pushed %0d expected %0d", pushed, DEPTH + 4));
    if (popped != DEPTH + 4) `lvm_rpt_err(("popped %0d expected %0d", popped, DEPTH + 4));
    if (mismatches != 0)     `lvm_rpt_err(("%0d mismatches", mismatches));
    $finish(0);
  end

  always #1ns    wclk = ~wclk;
  always #1500ps rclk = ~rclk;
endmodule
