// demo_tiny_alu_subsys_top — Multi-clock ALU accelerator.
//
// Three clock domains:
//   apb_clk     — APB bus + CSR block (demo_tiny_alu_subsys_csr, peakrdl-gen)
//   cclk        — compute domain (demo_tiny_alu_subsys_compute)
//   wclk = apb_clk for the streaming-input async FIFO write side
//                  (the *read* side runs in cclk, so the FIFO is the
//                   apb→cclk crossing for SRC=1 mode)
//
// Two CDC paths:
//   apb→cclk via ip_cdc_handshake (CSR-direct command)
//   cclk→apb via ip_cdc_handshake (result + flags)
//
// FIFO_FULL is naturally in apb domain (FIFO write side). FIFO_EMPTY
// is generated in cclk and synchronized to apb via ip_cdc_sync. BUSY
// is computed in apb domain from outstanding apb-side state.

module demo_tiny_alu_subsys_top (
  // APB host
  input  logic        apb_clk,
  input  logic        apb_rst_n,
  apb_intf.subordinate apb,

  // Compute domain clocks/resets
  input  logic        cclk,
  input  logic        crst_n
);

  // ────────── cclk reset synchroniser (RDC-008) ──────────
  // crst_n is an asynchronous primary reset. Synchronise its
  // *deassertion* to cclk so the compute-domain flops leave reset on a
  // clean cclk edge — an unsynchronised async-reset removal can violate
  // recovery/removal timing and let the cclk flops exit reset on
  // different cycles. Assertion stays asynchronous/immediate. Every
  // cclk consumer below takes crst_n_sync; the write side keeps its own
  // apb_rst_n (an async FIFO tolerates independent per-side reset).
  // SYNCASYNCNET is expected here and is the whole point: crst_sync_q is
  // clocked synchronously by cclk yet its output (crst_n_sync) drives the
  // async-reset pins of the cclk consumers — that dual use *is* the reset
  // synchroniser. Scope the waiver to this block only.
  /* verilator lint_off SYNCASYNCNET */
  (* ASYNC_REG = "TRUE", keep *) logic [1:0] crst_sync_q;
  always_ff @(posedge cclk or negedge crst_n) begin
    if (!crst_n) crst_sync_q <= 2'b00;
    else         crst_sync_q <= {crst_sync_q[0], 1'b1};
  end
  wire crst_n_sync = crst_sync_q[1];
  /* verilator lint_on SYNCASYNCNET */

  // ────────── CSR block ──────────
  demo_tiny_alu_subsys_csr_pkg::demo_tiny_alu_subsys_csr__in_t  hwif_in;
  demo_tiny_alu_subsys_csr_pkg::demo_tiny_alu_subsys_csr__out_t hwif_out;

  demo_tiny_alu_subsys_csr u_csr (
    .clk            (apb_clk),
    .rst_n          (apb_rst_n),
    .s_apb_psel     (apb.psel),
    .s_apb_penable  (apb.penable),
    .s_apb_pwrite   (apb.pwrite),
    .s_apb_pprot    (apb.pprot),
    .s_apb_paddr    (apb.paddr[4:0]),
    .s_apb_pwdata   (apb.pwdata),
    .s_apb_pstrb    (apb.pstrb),
    .s_apb_pready   (apb.pready),
    .s_apb_prdata   (apb.prdata),
    .s_apb_pslverr  (apb.pslverr),
    .hwif_in,
    .hwif_out
  );

  // ────────── apb→cclk: CSR-direct command via handshake ──────────
  logic [18:0] cmd_payload_apb;     // {op[2:0], a[7:0], b[7:0]}
  assign cmd_payload_apb = { hwif_out.op.OP.value,
                              hwif_out.operand_a.A.value,
                              hwif_out.operand_b.B.value };

  // src_valid: apb-side qualified GO pulse (only when SRC == 0)
  logic cmd_src_valid;
  logic cmd_src_ready;
  assign cmd_src_valid = hwif_out.ctrl.GO.value & ~hwif_out.ctrl.SRC.value;

  logic        cmd_dst_valid_cclk;
  logic [18:0] cmd_dst_data_cclk;

  ip_cdc_handshake #(.WIDTH(19)) u_hs_cmd (
    .src_clk   (apb_clk), .src_rst_n (apb_rst_n),
    .src_valid (cmd_src_valid), .src_ready (cmd_src_ready),
    .src_data  (cmd_payload_apb),
    .dst_clk   (cclk),    .dst_rst_n (crst_n_sync),
    .dst_valid (cmd_dst_valid_cclk),
    .dst_data  (cmd_dst_data_cclk)
  );

  // ────────── apb→cclk: streaming via async FIFO ──────────
  logic        fifo_wr_en, fifo_wr_full;
  logic [18:0] fifo_wr_data;
  assign fifo_wr_en   = hwif_out.fifo_push.PUSH.value & ~fifo_wr_full;
  assign fifo_wr_data = { hwif_out.fifo_push.OP.value,
                          hwif_out.fifo_push.A.value,
                          hwif_out.fifo_push.B.value };

  logic        fifo_rd_en, fifo_rd_empty;
  logic [18:0] fifo_rd_data;

  ip_async_fifo #(.DEPTH(8), .DATA_W(19)) u_afifo (
    .wclk     (apb_clk), .wrst_n (apb_rst_n),
    .wr_en    (fifo_wr_en),    .wr_data (fifo_wr_data), .wr_full (fifo_wr_full),
    .rclk     (cclk),    .rrst_n (crst_n_sync),
    .rd_en    (fifo_rd_en),    .rd_data (fifo_rd_data), .rd_empty (fifo_rd_empty)
  );

  // ────────── compute domain ──────────
  logic       src_sel_cclk;
  ip_cdc_sync #(.WIDTH(1), .STAGES(2)) u_sync_src (
    .clk(cclk), .rst_n(crst_n_sync), .d(hwif_out.ctrl.SRC.value), .q(src_sel_cclk)
  );

  logic       result_valid_cclk;
  logic [7:0] result_y_cclk;
  logic       result_zf_cclk, result_cf_cclk, result_nf_cclk, result_vf_cclk;
  logic       busy_cclk;

  demo_tiny_alu_subsys_compute u_compute (
    .clk           (cclk),
    .rst_n         (crst_n_sync),
    .src_sel       (src_sel_cclk),
    .cmd_valid     (cmd_dst_valid_cclk),
    .cmd_op        (cmd_dst_data_cclk[18:16]),
    .cmd_a         (cmd_dst_data_cclk[15:8]),
    .cmd_b         (cmd_dst_data_cclk[7:0]),
    .fifo_rd_en,
    .fifo_rd_data,
    .fifo_rd_empty,
    .result_valid  (result_valid_cclk),
    .result_y      (result_y_cclk),
    .result_zf     (result_zf_cclk),
    .result_cf     (result_cf_cclk),
    .result_nf     (result_nf_cclk),
    .result_vf     (result_vf_cclk),
    .busy          (busy_cclk)
  );

  // ────────── cclk→apb: result handshake ──────────
  logic [11:0] result_payload_cclk;        // {y[7:0], zf, cf, nf, vf}
  assign result_payload_cclk = { result_y_cclk,
                                  result_zf_cclk, result_cf_cclk,
                                  result_nf_cclk, result_vf_cclk };

  logic        result_dst_valid_apb;
  logic [11:0] result_dst_data_apb;

  ip_cdc_handshake #(.WIDTH(12)) u_hs_result (
    .src_clk   (cclk),    .src_rst_n (crst_n_sync),
    .src_valid (result_valid_cclk), .src_ready (/*ignored*/),
    .src_data  (result_payload_cclk),
    .dst_clk   (apb_clk), .dst_rst_n (apb_rst_n),
    .dst_valid (result_dst_valid_apb),
    .dst_data  (result_dst_data_apb)
  );

  // ────────── apb-side latched result + flags ──────────
  logic [7:0] latched_y;
  logic       latched_zf, latched_cf, latched_nf, latched_vf;
  logic [7:0] done_cnt_q;

  always_ff @(posedge apb_clk or negedge apb_rst_n) begin
    if (!apb_rst_n) begin
      latched_y  <= '0;
      latched_zf <= 1'b0; latched_cf <= 1'b0; latched_nf <= 1'b0; latched_vf <= 1'b0;
      done_cnt_q <= '0;
    end else if (result_dst_valid_apb) begin
      { latched_y, latched_zf, latched_cf, latched_nf, latched_vf } <= result_dst_data_apb;
      done_cnt_q <= done_cnt_q + 1'b1;
    end
  end

  // ────────── apb-side BUSY tracking ──────────
  // Sticky between GO/PUSH and result return; OR'd with synced FIFO non-empty.
  logic       fifo_empty_in_apb;
  ip_cdc_sync #(.WIDTH(1), .STAGES(2)) u_sync_empty (
    .clk(apb_clk), .rst_n(apb_rst_n), .d(fifo_rd_empty), .q(fifo_empty_in_apb)
  );

  logic pending_apb_q;
  always_ff @(posedge apb_clk or negedge apb_rst_n) begin
    if (!apb_rst_n)                          pending_apb_q <= 1'b0;
    else if (cmd_src_valid && cmd_src_ready) pending_apb_q <= 1'b1;
    else if (result_dst_valid_apb)           pending_apb_q <= 1'b0;
  end

  // ────────── hwif_in (CSR read-back) ──────────
  always_comb begin
    hwif_in.status.BUSY.next       = pending_apb_q | ~fifo_empty_in_apb;
    hwif_in.status.FIFO_FULL.next  = fifo_wr_full;
    hwif_in.status.FIFO_EMPTY.next = fifo_empty_in_apb;
    hwif_in.status.DONE_CNT.next   = done_cnt_q;
    hwif_in.result.Y.next          = latched_y;
    hwif_in.flags.ZF.next          = latched_zf;
    hwif_in.flags.CF.next          = latched_cf;
    hwif_in.flags.NF.next          = latched_nf;
    hwif_in.flags.VF.next          = latched_vf;
  end

  // Tie off unused
  /* verilator lint_off UNUSED */
  logic _unused = busy_cclk;
  /* verilator lint_on UNUSED */

endmodule
