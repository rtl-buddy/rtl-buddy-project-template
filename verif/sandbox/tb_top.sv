// vim: set ts=2 sw=2 et :
//
// Tiny ALU SV/LVM testbench.
//
// Strategy:
//  - Stimulus: directed sequences per test, selected by +TEST=<name> plusarg.
//  - Scoreboard: an inline SV reference function `ref_compute()` mirrors
//    the spec; every cycle we compare the registered DUT output to the
//    reference and bump the LVM error count on mismatch.
//  - Cosim with Python golden: every transaction is also written to
//    `txn.log` (cycle,op,a,b,y,zf,cf,nf,vf). After regression,
//    `build_report.py` replays the log through `spec/sandbox/sandbox_model.py`
//    to prove SV<->Python equivalence and to generate the DV report.
//  - Coverage: see `cov_alu.sv` (bound below).

`include "lvm_core.sv"

class EndHook implements LvmPkg::TestEndHook;
  virtual function void end_of_test(LvmPkg::TestCore c);
    $display("end_of_test: nerr=%0d", c.nerr);
  endfunction
endclass

module tb_top;
  `LVM_INIT("sandbox_alu")

  localparam int W = 8;

  logic         clk;
  logic         rst;
  logic [2:0]   op;
  logic [W-1:0] a, b;
  logic [W-1:0] y;
  logic         zf, cf, nf, vf;

  // sample of inputs aligned with the registered DUT outputs
  logic [2:0]   op_d1;
  logic [W-1:0] a_d1, b_d1;

  string        test_name = "basic";
  int           seed = 1;
  int           cycles = 64;

  EndHook eh;

  alu #(.W(W)) i_dut (
    .clk, .rst, .op, .a, .b, .y, .zf, .cf, .nf, .vf
  );

  // ----------------------------------------------------------------------
  // Reference: same algorithm as spec/sandbox/sandbox_model.py
  // ----------------------------------------------------------------------
  function automatic void ref_compute(
    input  logic [2:0]   r_op,
    input  logic [W-1:0] r_a,
    input  logic [W-1:0] r_b,
    output logic [W-1:0] r_y,
    output logic         r_zf, r_cf, r_nf, r_vf
  );
    logic [W:0] add_ext, sub_ext;
    r_cf = 1'b0; r_vf = 1'b0;
    case (r_op)
      3'd0: begin
        add_ext = {1'b0, r_a} + {1'b0, r_b};
        r_y  = add_ext[W-1:0];
        r_cf = add_ext[W];
        r_vf = (r_a[W-1] == r_b[W-1]) && (r_y[W-1] != r_a[W-1]);
      end
      3'd1: begin
        sub_ext = {1'b0, r_a} - {1'b0, r_b};
        r_y  = sub_ext[W-1:0];
        r_cf = sub_ext[W];
        r_vf = (r_a[W-1] != r_b[W-1]) && (r_y[W-1] != r_a[W-1]);
      end
      3'd2: r_y = r_a & r_b;
      3'd3: r_y = r_a | r_b;
      3'd4: r_y = r_a ^ r_b;
      3'd5: r_y = r_a << r_b[2:0];
      3'd6: r_y = r_a >> r_b[2:0];
      3'd7: r_y = '0;
      default: r_y = '0;
    endcase
    r_zf = (r_y == '0);
    r_nf = r_y[W-1];
  endfunction

  // ----------------------------------------------------------------------
  // Stimulus selection
  // ----------------------------------------------------------------------
  task automatic drive_basic();
    int unsigned i;
    for (i = 0; i < 8; i++) begin
      op = i[2:0];
      a  = 8'h12;
      b  = 8'h34;
      @(posedge clk);
    end
  endtask

  task automatic drive_ops_sweep();
    int unsigned i;
    op = 3'd0; a = 8'h00; b = 8'h00;
    for (i = 0; i < 8; i++) begin
      op = i[2:0];
      a  = 8'(i * 11);
      b  = 8'(i * 7 + 3);
      @(posedge clk);
    end
  endtask

  task automatic drive_flags();
    // ADD overflow + carry
    op = 3'd0; a = 8'h7F; b = 8'h01; @(posedge clk);  // V on signed
    op = 3'd0; a = 8'hFF; b = 8'h01; @(posedge clk);  // C carry-out, Z=1
    // SUB borrow
    op = 3'd1; a = 8'h00; b = 8'h01; @(posedge clk);  // C borrow
    op = 3'd1; a = 8'h80; b = 8'h01; @(posedge clk);  // V signed
    // negative result
    op = 3'd1; a = 8'h00; b = 8'h7F; @(posedge clk);  // N=1
    // zero result via XOR
    op = 3'd4; a = 8'h5A; b = 8'h5A; @(posedge clk);  // Z=1
    op = 3'd7; a = 8'hAA; b = 8'h55; @(posedge clk);  // NOP
  endtask

  task automatic drive_random();
    int unsigned i;
    for (i = 0; i < cycles; i++) begin
      op = $urandom_range(0, 7);
      a  = $urandom();
      b  = $urandom();
      @(posedge clk);
    end
  endtask

  // ----------------------------------------------------------------------
  // Scoreboard + transaction log
  // ----------------------------------------------------------------------
  int          txn_fd;
  int unsigned cycle_idx;
  int unsigned mismatches;

  always_ff @(posedge clk) begin
    op_d1 <= op;
    a_d1  <= a;
    b_d1  <= b;
  end

  always @(posedge clk) begin
    if (!rst) begin
      logic [W-1:0] r_y;
      logic         r_zf, r_cf, r_nf, r_vf;
      ref_compute(op_d1, a_d1, b_d1, r_y, r_zf, r_cf, r_nf, r_vf);
      if ({y,zf,cf,nf,vf} !== {r_y,r_zf,r_cf,r_nf,r_vf}) begin
        mismatches <= mismatches + 1;
        `lvm_rpt_err(("scoreboard mismatch cycle=%0d op=%0d a=%h b=%h dut=%h{%b%b%b%b} ref=%h{%b%b%b%b}",
          cycle_idx, op_d1, a_d1, b_d1, y, zf, cf, nf, vf,
          r_y, r_zf, r_cf, r_nf, r_vf));
      end
      if (txn_fd != 0) begin
        $fdisplay(txn_fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
          cycle_idx, op_d1, a_d1, b_d1, y, zf, cf, nf, vf);
      end
      cycle_idx <= cycle_idx + 1;
    end
  end

  // ----------------------------------------------------------------------
  // Top-level flow
  // ----------------------------------------------------------------------
  initial begin
    eh = new();
    tc.add_test_end_hook(eh);

    clk = 1'b0;
    rst = 1'b1;
    op  = 3'd7; a = '0; b = '0;
    cycle_idx  = 0;
    mismatches = 0;

    void'($value$plusargs("TEST=%s", test_name));
    void'($value$plusargs("SEED=%d", seed));
    void'($value$plusargs("CYCLES=%d", cycles));
    $urandom(seed);

    txn_fd = $fopen("txn.log", "w");
    if (txn_fd != 0)
      $fdisplay(txn_fd, "# cycle,op,a,b,y,zf,cf,nf,vf");

    `lvm_rpt_inf(("test starting: %s seed=%0d cycles=%0d", test_name, seed, cycles));

    repeat (4) @(posedge clk);
    rst = 1'b0;
    @(posedge clk);

    case (test_name)
      "basic":          drive_basic();
      "ops_sweep":      drive_ops_sweep();
      "flags":          drive_flags();
      "random":         drive_random();
      default: begin
        `lvm_rpt_err(("unknown test %s", test_name));
      end
    endcase

    repeat (4) @(posedge clk);
    if (txn_fd != 0) $fclose(txn_fd);
    `lvm_rpt_inf(("test done: %s mismatches=%0d", test_name, mismatches));
    $finish(0);
  end

  always #500ps clk = ~clk;

  // bind covergroups
  bind alu cov_alu u_cov (.*);

endmodule
