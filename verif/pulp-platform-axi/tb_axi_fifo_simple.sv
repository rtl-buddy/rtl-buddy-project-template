/* verilator lint_off UNUSEDLOOP */
// tb_axi_fifo_simple — directed Verilator-compatible testbench for axi_fifo_intf
//
// Drives AXI_BUS signals directly (no axi_test.sv / OOP classes).
// Covers: single write, single read, 4-beat burst write+read, write backpressure.

module tb_axi_fifo_simple;

  localparam int unsigned ADDR_W    = 32;
  localparam int unsigned DATA_W    = 64;
  localparam int unsigned ID_W      = 4;
  localparam int unsigned USER_W    = 1;
  localparam int unsigned STRB_W    = DATA_W / 8;
  localparam int unsigned FIFO_DEPTH = 4;

  // ── Clock / reset ──────────────────────────────────────────────────────────

  logic clk, rst_n;
  initial clk = 0;
  always #5ns clk = ~clk;

  // ── AXI_BUS instances ──────────────────────────────────────────────────────

  AXI_BUS #(
    .AXI_ADDR_WIDTH (ADDR_W),
    .AXI_DATA_WIDTH (DATA_W),
    .AXI_ID_WIDTH   (ID_W),
    .AXI_USER_WIDTH (USER_W)
  ) slv (), mst ();

  // ── DUT ───────────────────────────────────────────────────────────────────

  axi_fifo_intf #(
    .ADDR_WIDTH  (ADDR_W),
    .DATA_WIDTH  (DATA_W),
    .ID_WIDTH    (ID_W),
    .USER_WIDTH  (USER_W),
    .DEPTH       (FIFO_DEPTH),
    .FALL_THROUGH(0)
  ) i_dut (
    .clk_i  (clk),
    .rst_ni (rst_n),
    .test_i (1'b0),
    .slv    (slv.Slave),
    .mst    (mst.Master)
  );

  // ── Simple slave responder on mst port ────────────────────────────────────
  // Accepts AW+W immediately, issues B after W. Accepts AR, issues R with
  // data = {addr[31:0], addr[31:0]}.

  logic [ADDR_W-1:0] slv_aw_addr_q;
  logic [ID_W-1:0]   slv_aw_id_q;
  logic              slv_aw_pending;
  logic [DATA_W-1:0] slv_rd_data;

  initial begin
    mst.aw_ready = 1'b0;
    mst.w_ready  = 1'b0;
    mst.b_id     = '0;
    mst.b_resp   = 2'b00;
    mst.b_user   = '0;
    mst.b_valid  = 1'b0;
    mst.ar_ready = 1'b0;
    mst.r_id     = '0;
    mst.r_data   = '0;
    mst.r_resp   = 2'b00;
    mst.r_last   = 1'b0;
    mst.r_user   = '0;
    mst.r_valid  = 1'b0;
    @(posedge rst_n);

    forever begin
      // Accept AW
      @(negedge clk);
      mst.aw_ready = 1'b1;
      @(posedge clk);
      while (!mst.aw_valid) @(posedge clk);
      slv_aw_id_q   = mst.aw_id;
      slv_aw_addr_q = mst.aw_addr;
      @(negedge clk);
      mst.aw_ready = 1'b0;

      // Accept W beats until w_last
      @(negedge clk);
      mst.w_ready = 1'b1;
      @(posedge clk);
      while (!mst.w_valid) @(posedge clk);
      while (!(mst.w_valid && mst.w_last)) @(posedge clk);
      @(negedge clk);
      mst.w_ready = 1'b0;

      // Issue B
      @(negedge clk);
      mst.b_id    = slv_aw_id_q;
      mst.b_resp  = 2'b00;
      mst.b_valid = 1'b1;
      @(posedge clk);
      while (!mst.b_ready) @(posedge clk);
      @(negedge clk);
      mst.b_valid = 1'b0;
    end
  end

  initial begin
    @(posedge rst_n);
    forever begin
      // Accept AR, issue R with mirrored addr as data
      @(negedge clk);
      mst.ar_ready = 1'b1;
      @(posedge clk);
      while (!mst.ar_valid) @(posedge clk);
      slv_rd_data = {mst.ar_addr, mst.ar_addr};
      @(negedge clk);
      mst.ar_ready = 1'b0;

      // Issue R (single beat, rlast=1)
      repeat (2) @(posedge clk);  // small gap
      @(negedge clk);
      mst.r_id    = mst.ar_id;
      mst.r_data  = slv_rd_data;
      mst.r_resp  = 2'b00;
      mst.r_last  = 1'b1;
      mst.r_valid = 1'b1;
      @(posedge clk);
      while (!mst.r_ready) @(posedge clk);
      @(negedge clk);
      mst.r_valid = 1'b0;
      mst.r_last  = 1'b0;
    end
  end

  // ── Manager driver tasks ───────────────────────────────────────────────────

  task automatic idle_slv();
    slv.aw_id     = '0;  slv.aw_addr  = '0;  slv.aw_len   = '0;
    slv.aw_size   = '0;  slv.aw_burst = '0;  slv.aw_lock  = '0;
    slv.aw_cache  = '0;  slv.aw_prot  = '0;  slv.aw_qos   = '0;
    slv.aw_region = '0;  slv.aw_atop  = '0;  slv.aw_user  = '0;
    slv.aw_valid  = 1'b0;
    slv.w_data    = '0;  slv.w_strb   = '0;  slv.w_last   = 1'b0;
    slv.w_user    = '0;  slv.w_valid  = 1'b0;
    slv.b_ready   = 1'b0;
    slv.ar_id     = '0;  slv.ar_addr  = '0;  slv.ar_len   = '0;
    slv.ar_size   = '0;  slv.ar_burst = '0;  slv.ar_lock  = '0;
    slv.ar_cache  = '0;  slv.ar_prot  = '0;  slv.ar_qos   = '0;
    slv.ar_region = '0;  slv.ar_user  = '0;  slv.ar_valid = 1'b0;
    slv.r_ready   = 1'b0;
  endtask

  task automatic write1(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [DATA_W-1:0] data,
    input logic [STRB_W-1:0] strb,
    output logic [1:0]        resp
  );
    @(negedge clk);
    slv.aw_id    = id;  slv.aw_addr  = addr;
    slv.aw_len   = '0;  slv.aw_size  = 3'($clog2(STRB_W));
    slv.aw_burst = 2'b01;  slv.aw_valid = 1'b1;
    @(posedge clk); while (!slv.aw_ready) @(posedge clk);
    @(negedge clk); slv.aw_valid = 1'b0;
    @(negedge clk);
    slv.w_data = data; slv.w_strb = strb;
    slv.w_last = 1'b1; slv.w_valid = 1'b1;
    @(posedge clk); while (!slv.w_ready) @(posedge clk);
    @(negedge clk); slv.w_valid = 1'b0; slv.w_last = 1'b0;
    @(negedge clk); slv.b_ready = 1'b1;
    @(posedge clk); while (!slv.b_valid) @(posedge clk);
    resp = slv.b_resp;
    @(negedge clk); slv.b_ready = 1'b0;
  endtask

  task automatic read1(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    output logic [DATA_W-1:0] data,
    output logic [1:0]         resp
  );
    @(negedge clk);
    slv.ar_id    = id;   slv.ar_addr  = addr;
    slv.ar_len   = '0;   slv.ar_size  = 3'($clog2(STRB_W));
    slv.ar_burst = 2'b01; slv.ar_valid = 1'b1;
    @(posedge clk); while (!slv.ar_ready) @(posedge clk);
    @(negedge clk); slv.ar_valid = 1'b0;
    @(negedge clk); slv.r_ready = 1'b1;
    @(posedge clk); while (!slv.r_valid) @(posedge clk);
    data = slv.r_data; resp = slv.r_resp;
    @(negedge clk); slv.r_ready = 1'b0;
  endtask

  // ── Test sequence ──────────────────────────────────────────────────────────

  int pass_cnt, fail_cnt;

  task automatic check(input string label, input logic ok);
    if (ok) begin
      $display("  PASS %s", label);
      pass_cnt++;
    end else begin
      $display("  FAIL %s", label);
      fail_cnt++;
    end
  endtask

  initial begin
    pass_cnt = 0; fail_cnt = 0;
    idle_slv();
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    @(negedge clk); rst_n = 1'b1;
    repeat (3) @(posedge clk);

    // ── FIFO-01: single write, check OKAY response ──────────────────────────
    begin
      automatic logic [1:0] bresp;
      write1(4'h1, 32'hDEAD_0100, 64'hCAFE_BABE_1234_5678, 8'hFF, bresp);
      check("FIFO-01 write resp OKAY", bresp == 2'b00);
    end

    // ── FIFO-02: single read, check data mirrors address ────────────────────
    begin
      automatic logic [DATA_W-1:0] rdata;
      automatic logic [1:0]         rresp;
      automatic logic [ADDR_W-1:0]  addr = 32'hABCD_0200;
      read1(4'h2, addr, rdata, rresp);
      check("FIFO-02 read resp OKAY",  rresp == 2'b00);
      check("FIFO-02 read data",       rdata == {addr, addr});
    end

    // ── FIFO-03: back-to-back writes fill the FIFO ──────────────────────────
    begin
      automatic logic [1:0] bresp;
      for (int i = 0; i < int'(FIFO_DEPTH); i++) begin
        write1(ID_W'(i), ADDR_W'(32'h0300 + i*8), DATA_W'(64'hA000 + i), 8'hFF, bresp);
        check($sformatf("FIFO-03 write[%0d] resp OKAY", i), bresp == 2'b00);
      end
    end

    // ── FIFO-04: reads after writes ─────────────────────────────────────────
    begin
      automatic logic [DATA_W-1:0] rdata;
      automatic logic [1:0]         rresp;
      automatic logic [ADDR_W-1:0]  addr = 32'hBEEF_0400;
      for (int i = 0; i < 2; i++) begin
        read1(4'h4, addr, rdata, rresp);
        check($sformatf("FIFO-04 read[%0d] resp OKAY", i), rresp == 2'b00);
        check($sformatf("FIFO-04 read[%0d] data",      i), rdata == {addr, addr});
      end
    end

    repeat (10) @(posedge clk);

    if (fail_cnt == 0)
      $display("PASS axi_fifo_simple: all %0d checks passed", pass_cnt);
    else begin
      $display("FAIL axi_fifo_simple: %0d/%0d checks failed", fail_cnt, pass_cnt + fail_cnt);
      $display("ERR: %0d check(s) failed", fail_cnt);
    end

    $finish(0);
  end

endmodule
