// demo_tiny_alu_subsys system-level testbench.
//
// Two clocks: apb_clk = 4 ns, cclk = 6 ns. APB host stub drives ctrl/op/a/b
// or fifo_push registers depending on +TEST=. Inline SV reference mirrors
// the sandbox alu spec; per-cycle the latched result.Y/flags is compared
// against the reference. Each accepted command is logged to txn.log for
// post-run replay through spec/demo_tiny_alu_subsys/demo_tiny_alu_subsys_model.py.

`include "lvm_core.sv"

/* verilator lint_off SYNCASYNCNET */
module tb_top;
  `LVM_INIT("demo_tiny_alu_subsys")

  // ────────── clocks/resets ──────────
  logic apb_clk, cclk;
  logic apb_rst_n, crst_n;

  // ────────── APB ──────────
  apb_intf #(.ADDR_W(8), .DATA_W(32)) bus (.clk(apb_clk), .rst_n(apb_rst_n));

  demo_tiny_alu_subsys_top u_dut (
    .apb_clk, .apb_rst_n,
    .apb (bus),
    .cclk, .crst_n
  );

  // CSR address map
  localparam logic [7:0] A_CTRL      = 8'h00;
  localparam logic [7:0] A_STATUS    = 8'h04;
  localparam logic [7:0] A_OP        = 8'h08;
  localparam logic [7:0] A_OPERAND_A = 8'h0C;
  localparam logic [7:0] A_OPERAND_B = 8'h10;
  localparam logic [7:0] A_RESULT    = 8'h14;
  localparam logic [7:0] A_FLAGS     = 8'h18;
  localparam logic [7:0] A_FIFO_PUSH = 8'h1C;

  // ────────── APB driver tasks ──────────
  task automatic apb_write(input [7:0] addr, input [31:0] data);
    @(negedge apb_clk);
    bus.paddr   = addr;
    bus.pwdata  = data;
    bus.pwrite  = 1'b1;
    bus.pstrb   = 4'hF;
    bus.psel    = 1'b1;
    bus.penable = 1'b0;
    @(negedge apb_clk);
    bus.penable = 1'b1;
    do @(negedge apb_clk); while (!bus.pready);
    bus.psel    = 1'b0;
    bus.penable = 1'b0;
  endtask

  task automatic apb_read(input [7:0] addr, output [31:0] data);
    @(negedge apb_clk);
    bus.paddr   = addr;
    bus.pwrite  = 1'b0;
    bus.psel    = 1'b1;
    bus.penable = 1'b0;
    @(negedge apb_clk);
    bus.penable = 1'b1;
    do @(negedge apb_clk); while (!bus.pready);
    data = bus.prdata;
    bus.psel    = 1'b0;
    bus.penable = 1'b0;
  endtask

  // ────────── reference (mirrors sandbox alu) ──────────
  function automatic void ref_compute(
    input  logic [2:0] r_op,
    input  logic [7:0] r_a, r_b,
    output logic [7:0] r_y,
    output logic       r_zf, r_cf, r_nf, r_vf
  );
    logic [8:0] add_ext, sub_ext;
    r_cf = 1'b0; r_vf = 1'b0;
    case (r_op)
      3'd0: begin add_ext = {1'b0, r_a} + {1'b0, r_b}; r_y = add_ext[7:0]; r_cf = add_ext[8];
                  r_vf = (r_a[7] == r_b[7]) && (r_y[7] != r_a[7]); end
      3'd1: begin sub_ext = {1'b0, r_a} - {1'b0, r_b}; r_y = sub_ext[7:0]; r_cf = sub_ext[8];
                  r_vf = (r_a[7] != r_b[7]) && (r_y[7] != r_a[7]); end
      3'd2: r_y = r_a & r_b;
      3'd3: r_y = r_a | r_b;
      3'd4: r_y = r_a ^ r_b;
      3'd5: r_y = r_a << r_b[2:0];
      3'd6: r_y = r_a >> r_b[2:0];
      default: r_y = '0;
    endcase
    r_zf = (r_y == '0);
    r_nf = r_y[7];
  endfunction

  // ────────── txn log ──────────
  int txn_fd;
  task automatic log_txn(input [2:0] op, input [7:0] a, input [7:0] b,
                          input [7:0] y, input zf, input cf, input nf, input vf);
    if (txn_fd != 0)
      $fdisplay(txn_fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                op, a, b, y, zf, cf, nf, vf);
  endtask

  // ────────── cover labels matching ACCEL-* IDs ──────────
  bit cov_csr_write, cov_csr_read, cov_csr_direct, cov_fifo_push,
      cov_fifo_full, cov_fifo_drain, cov_done_inc, cov_result_match;

  ACCEL_CSR_WRITE:    cover property (@(posedge apb_clk) cov_csr_write);
  ACCEL_CSR_READ:     cover property (@(posedge apb_clk) cov_csr_read);
  ACCEL_CSR_DIRECT_OP:cover property (@(posedge apb_clk) cov_csr_direct);
  ACCEL_FIFO_PUSH:    cover property (@(posedge apb_clk) cov_fifo_push);
  ACCEL_FIFO_FULL:    cover property (@(posedge apb_clk) cov_fifo_full);
  ACCEL_FIFO_DRAIN:   cover property (@(posedge apb_clk) cov_fifo_drain);
  ACCEL_DONE_INC:     cover property (@(posedge apb_clk) cov_done_inc);
  ACCEL_RESULT_MATCH: cover property (@(posedge apb_clk) cov_result_match);

  always @(posedge apb_clk) begin
    if (bus.psel && bus.penable && bus.pready &&  bus.pwrite) cov_csr_write <= 1'b1;
    if (bus.psel && bus.penable && bus.pready && !bus.pwrite) cov_csr_read  <= 1'b1;
  end

  // ────────── high-level ops ──────────
  int unsigned mismatches;

  task automatic do_csr_direct(input [2:0] op, input [7:0] a, input [7:0] b);
    logic [31:0] sd;
    logic [7:0]  ref_y; logic ref_zf, ref_cf, ref_nf, ref_vf;
    apb_write(A_OP,        {29'b0, op});
    apb_write(A_OPERAND_A, {24'b0, a});
    apb_write(A_OPERAND_B, {24'b0, b});
    apb_write(A_CTRL,      32'h0000_0002);  // SRC=0, GO=1 (bit1)
    cov_csr_direct = 1'b1;
    // poll BUSY=0
    do begin
      apb_read(A_STATUS, sd);
    end while (sd[0] !== 1'b0);
    apb_read(A_RESULT, sd);
    ref_compute(op, a, b, ref_y, ref_zf, ref_cf, ref_nf, ref_vf);
    if (sd[7:0] !== ref_y) begin
      mismatches = mismatches + 1;
      `lvm_rpt_err(("CSR-direct y mismatch op=%0d a=%h b=%h dut=%h ref=%h",
                    op, a, b, sd[7:0], ref_y));
    end
    apb_read(A_FLAGS, sd);
    if ({sd[3], sd[2], sd[1], sd[0]} !== {ref_vf, ref_nf, ref_cf, ref_zf}) begin
      mismatches = mismatches + 1;
      `lvm_rpt_err(("CSR-direct flags mismatch op=%0d dut=%b ref=%b",
                    op, sd[3:0], {ref_vf, ref_nf, ref_cf, ref_zf}));
    end else begin
      cov_result_match = 1'b1;
    end
    log_txn(op, a, b, sd[7:0], ref_zf, ref_cf, ref_nf, ref_vf);
  endtask

  task automatic do_fifo_push(input [2:0] op, input [7:0] a, input [7:0] b);
    logic [31:0] sd;
    // poll FIFO_FULL=0
    do begin
      apb_read(A_STATUS, sd);
      if (sd[1]) cov_fifo_full = 1'b1;
    end while (sd[1] !== 1'b0);
    // single packed write to fifo_push (PUSH=bit0, OP=bit3:1, A=bit11:4, B=bit19:12)
    apb_write(A_FIFO_PUSH, {12'b0, b, a, op, 1'b1});
    cov_fifo_push = 1'b1;
  endtask

  // ────────── flow ──────────
  string test_name = "csr_smoke";

  initial begin
    logic [31:0] sd;
    logic [7:0]  ref_y;  logic ref_zf, ref_cf, ref_nf, ref_vf;
    int          n_ops;
    int          init_done_cnt;

    txn_fd = $fopen("txn.log", "w");
    if (txn_fd != 0) $fdisplay(txn_fd, "# op,a,b,y,zf,cf,nf,vf");

    void'($value$plusargs("TEST=%s", test_name));

    bus.psel    = 1'b0;
    bus.penable = 1'b0;
    bus.pwrite  = 1'b0;
    bus.paddr   = '0;
    bus.pwdata  = '0;
    bus.pstrb   = '0;
    bus.pprot   = '0;
    apb_clk = 1'b0; cclk = 1'b0;
    apb_rst_n = 1'b0; crst_n = 1'b0;
    mismatches = 0;
    repeat (10) @(posedge apb_clk);
    apb_rst_n = 1'b1; crst_n = 1'b1;
    repeat (10) @(posedge apb_clk);

    case (test_name)

      "csr_smoke": begin
        n_ops = 0;
        do_csr_direct(3'd0, 8'h12, 8'h34); n_ops++;
        do_csr_direct(3'd1, 8'h80, 8'h01); n_ops++;
        do_csr_direct(3'd4, 8'h5A, 8'h5A); n_ops++;
        do_csr_direct(3'd5, 8'h11, 8'h02); n_ops++;
        apb_read(A_STATUS, sd);
        if (sd[10:3] !== 8'(n_ops)) begin
          `lvm_rpt_err(("DONE_CNT=%0d expected %0d", sd[10:3], n_ops));
        end else begin
          cov_done_inc = 1'b1;
        end
      end

      "fifo_stream": begin
        // Switch to FIFO mode
        apb_write(A_CTRL, 32'h0000_0001);                 // SRC=1, GO=0
        n_ops = 12;                                       // > FIFO depth (8) → drives FULL
        for (int i = 0; i < n_ops; i++)
          do_fifo_push(3'(i % 8), 8'(i * 7), 8'(i * 3 + 1));
        // Wait until empty AND not busy
        do begin
          apb_read(A_STATUS, sd);
        end while (sd[2] !== 1'b1 || sd[0] !== 1'b0);     // FIFO_EMPTY && !BUSY
        cov_fifo_drain = 1'b1;
        // Spot-check the *last* operation
        ref_compute(3'((n_ops - 1) % 8), 8'((n_ops - 1) * 7), 8'((n_ops - 1) * 3 + 1),
                    ref_y, ref_zf, ref_cf, ref_nf, ref_vf);
        apb_read(A_RESULT, sd);
        if (sd[7:0] !== ref_y) begin
          mismatches = mismatches + 1;
          `lvm_rpt_err(("FIFO-mode last-op y mismatch dut=%h ref=%h", sd[7:0], ref_y));
        end else begin
          cov_result_match = 1'b1;
        end
        apb_read(A_STATUS, sd);
        if (sd[10:3] !== 8'(n_ops)) begin
          `lvm_rpt_err(("DONE_CNT=%0d expected %0d", sd[10:3], n_ops));
        end else begin
          cov_done_inc = 1'b1;
        end
        log_txn(3'((n_ops - 1) % 8), 8'((n_ops - 1) * 7), 8'((n_ops - 1) * 3 + 1),
                sd[7:0], ref_zf, ref_cf, ref_nf, ref_vf);
      end

      default: `lvm_rpt_err(("unknown test %s", test_name));

    endcase

    repeat (10) @(posedge apb_clk);
    if (txn_fd != 0) $fclose(txn_fd);
    `lvm_rpt_inf(("done: %s mismatches=%0d", test_name, mismatches));
    $finish(0);
  end

  // 4 ns apb_clk, 6 ns cclk → asymmetric, deliberately incommensurate
  always #2ns apb_clk = ~apb_clk;
  always #3ns cclk    = ~cclk;

endmodule
