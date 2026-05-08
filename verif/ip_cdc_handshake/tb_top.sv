// ip_cdc_handshake standalone testbench.
// Two clocks at different rates. Source pushes a sequence of payloads;
// scoreboard expects them to land in dst_data on dst_valid pulses.
`include "lvm_core.sv"

module tb_top;
  `LVM_INIT("ip_cdc_handshake")
  localparam int W = 8;

  logic         src_clk, src_rst_n;
  logic         dst_clk, dst_rst_n;
  logic         src_valid, src_ready;
  logic [W-1:0] src_data;
  logic         dst_valid;
  logic [W-1:0] dst_data;

  ip_cdc_handshake #(.WIDTH(W)) u_dut (
    .src_clk, .src_rst_n, .src_valid, .src_ready, .src_data,
    .dst_clk, .dst_rst_n, .dst_valid, .dst_data
  );

  // Reference queue (`active` gates the scoreboard until both resets are
  // released and the source has accepted at least one transfer)
  bit [W-1:0] expected[$];
  int unsigned mismatches;
  int unsigned xfers;
  bit          active;

  always_ff @(posedge dst_clk) begin
    if (active && dst_valid) begin
      if (expected.size() == 0) begin
        mismatches <= mismatches + 1;
        `lvm_rpt_err(("dst_valid with no pending payload, dst_data=%h", dst_data));
      end else begin
        bit [W-1:0] e;
        e = expected.pop_front();
        if (dst_data !== e) begin
          mismatches <= mismatches + 1;
          `lvm_rpt_err(("payload mismatch dst=%h ref=%h", dst_data, e));
        end
      end
      xfers <= xfers + 1;
    end
  end

  // Cover labels — match HSCDC-* IDs
  HSCDC_XFER:         cover property (@(posedge dst_clk) dst_valid);
  HSCDC_DATA_MATCH:   cover property (@(posedge dst_clk) dst_valid && expected.size() != 0 && dst_data == expected[0]);
  HSCDC_BACKPRESSURE: cover property (@(posedge src_clk) !src_ready);

  task automatic push_payload(input bit [W-1:0] p);
    @(negedge src_clk);
    while (!src_ready) @(negedge src_clk);
    src_data  = p;
    src_valid = 1'b1;
    expected.push_back(p);
    @(negedge src_clk);
    src_valid = 1'b0;
  endtask

  initial begin
    mismatches = 0; xfers = 0; active = 1'b0;
    src_clk = 1'b0; dst_clk = 1'b0;
    src_rst_n = 1'b0; dst_rst_n = 1'b0;
    src_valid = 1'b0; src_data = '0;
    repeat (8) @(posedge dst_clk);
    src_rst_n = 1'b1;
    dst_rst_n = 1'b1;
    repeat (4) @(posedge dst_clk);
    active = 1'b1;

    // 6 transfers — covers MULTI-XFER (≥4)
    for (int i = 0; i < 6; i++) push_payload(8'(i * 17 + 3));

    // wait for drain
    repeat (60) @(posedge dst_clk);

    if (xfers < 6) `lvm_rpt_err(("only %0d/6 xfers observed", xfers));
    if (mismatches != 0) `lvm_rpt_err(("%0d mismatches", mismatches));
    $finish(0);
  end

  // Asymmetric clocks: src=2ns, dst=3ns (≈1.5×)
  always #1ns src_clk = ~src_clk;
  always #1500ps dst_clk = ~dst_clk;

  HSCDC_MULTI_XFER: cover property (@(posedge dst_clk) xfers >= 4);

endmodule
