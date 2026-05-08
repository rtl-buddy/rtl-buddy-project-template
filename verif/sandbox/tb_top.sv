// vim: set ts=2 sw=2 et :
//
// Tiny ALU SV/LVM testbench, vector-driven.
//
// `verif/sandbox/preproc.py` runs before compile and writes a
// `vectors.txt` file containing one line per cycle:
//
//   op, a, b, y, zf, cf, nf, vf
//
// where (y, zf, cf, nf, vf) is the expected DUT output produced by
// running (op, a, b) through the Python golden in
// `spec/sandbox/sandbox_model.py`. The absolute path is passed in via
// the `VECTORS` plusarg.
//
// At sim time we drive each (op, a, b) one row per clock, then compare
// the registered DUT outputs against the expected on the following
// cycle. Any mismatch increments the LVM error count → FAIL.
//
// txn.log is still emitted (cycle, op, a, b, dut_y, …) — it feeds the
// DV report's per-test markdown but the report no longer re-checks
// against the golden; SV-side checking against the preproc-generated
// expected is the authoritative pass/fail signal.

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

  EndHook eh;

  alu #(.W(W)) i_dut (
    .clk, .rst, .op, .a, .b, .y, .zf, .cf, .nf, .vf
  );

  // Vector storage. Sized for the largest sequence we currently use.
  localparam int MAX_VECTORS = 1024;
  bit [2:0]     v_op  [MAX_VECTORS];
  bit [W-1:0]   v_a   [MAX_VECTORS];
  bit [W-1:0]   v_b   [MAX_VECTORS];
  bit [W-1:0]   v_y   [MAX_VECTORS];
  bit           v_zf  [MAX_VECTORS];
  bit           v_cf  [MAX_VECTORS];
  bit           v_nf  [MAX_VECTORS];
  bit           v_vf  [MAX_VECTORS];
  int          n_vectors;

  // Reads vectors.txt produced by preproc.py. CSV; lines starting with
  // `#` are comments. One row per cycle: op,a,b,y,zf,cf,nf,vf.
  task automatic load_vectors(input string path);
    int           fd;
    string        line;
    int           code;
    int           tmp_op, tmp_a, tmp_b, tmp_y, tmp_zf, tmp_cf, tmp_nf, tmp_vf;
    fd = $fopen(path, "r");
    if (fd == 0) begin
      `lvm_rpt_err(("failed to open VECTORS=%s", path));
      return;
    end
    n_vectors = 0;
    while (!$feof(fd)) begin
      code = $fgets(line, fd);
      if (code == 0) break;
      if (line.len() == 0 || line[0] == "#" || line[0] == "\n") continue;
      code = $sscanf(line, "%d,%d,%d,%d,%d,%d,%d,%d",
                     tmp_op, tmp_a, tmp_b, tmp_y, tmp_zf, tmp_cf, tmp_nf, tmp_vf);
      if (code != 8) continue;
      if (n_vectors >= MAX_VECTORS) begin
        `lvm_rpt_err(("vectors exceed MAX_VECTORS=%0d", MAX_VECTORS));
        break;
      end
      v_op [n_vectors] = tmp_op[2:0];
      v_a  [n_vectors] = tmp_a[W-1:0];
      v_b  [n_vectors] = tmp_b[W-1:0];
      v_y  [n_vectors] = tmp_y[W-1:0];
      v_zf [n_vectors] = tmp_zf[0];
      v_cf [n_vectors] = tmp_cf[0];
      v_nf [n_vectors] = tmp_nf[0];
      v_vf [n_vectors] = tmp_vf[0];
      n_vectors++;
    end
    $fclose(fd);
    `lvm_rpt_inf(("loaded %0d vectors from %s", n_vectors, path));
  endtask

  // ────────── Scoreboard + transaction log ──────────
  int          txn_fd;
  int unsigned cycle_idx;
  int unsigned mismatches;

  // Drive op_d1/a_d1/b_d1 carry the input that produced the *current*
  // registered DUT output, so we know which expected vector to compare.
  bit [2:0]   op_d1;
  bit [W-1:0] a_d1, b_d1;
  bit         have_d1;
  int         issue_idx;          // index of next vector to drive
  int         check_idx;          // index of next vector to check

  task automatic drive_and_check();
    int i;
    for (i = 0; i < n_vectors; i++) begin
      op = v_op[i];
      a  = v_a[i];
      b  = v_b[i];
      @(posedge clk);
      // After this edge, y holds the registered result of inputs (op,a,b)
      // sampled at this same edge.
      compare(i);
      if (txn_fd != 0)
        $fdisplay(txn_fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                  cycle_idx, v_op[i], v_a[i], v_b[i], y, zf, cf, nf, vf);
      cycle_idx++;
    end
  endtask

  task automatic compare(input int idx);
    if ({y, zf, cf, nf, vf} !== {v_y[idx], v_zf[idx], v_cf[idx], v_nf[idx], v_vf[idx]}) begin
      mismatches++;
      `lvm_rpt_err(("vector[%0d] mismatch op=%0d a=%h b=%h dut={y=%h,z%b c%b n%b v%b} exp={y=%h,z%b c%b n%b v%b}",
        idx, v_op[idx], v_a[idx], v_b[idx],
        y, zf, cf, nf, vf,
        v_y[idx], v_zf[idx], v_cf[idx], v_nf[idx], v_vf[idx]));
    end
  endtask

  // ────────── Top-level flow ──────────
  initial begin
    string vectors_path;

    eh = new();
    tc.add_test_end_hook(eh);

    clk = 1'b0;
    rst = 1'b1;
    op  = 3'd7; a = '0; b = '0;
    cycle_idx  = 0;
    mismatches = 0;

    if (!$value$plusargs("VECTORS=%s", vectors_path)) begin
      `lvm_rpt_err(("missing VECTORS plusarg — preproc must run before sim"));
      $finish(0);
    end

    txn_fd = $fopen("txn.log", "w");
    if (txn_fd != 0)
      $fdisplay(txn_fd, "# cycle,op,a,b,y,zf,cf,nf,vf");

    `lvm_rpt_inf(("sandbox tb starting: %s", vectors_path));

    repeat (4) @(posedge clk);
    rst = 1'b0;
    @(posedge clk);

    load_vectors(vectors_path);
    if (n_vectors > 0) drive_and_check();

    repeat (4) @(posedge clk);
    if (txn_fd != 0) $fclose(txn_fd);
    `lvm_rpt_inf(("sandbox tb done: vectors=%0d mismatches=%0d", n_vectors, mismatches));
    $finish(0);
  end

  always #500ps clk = ~clk;

  // bind covergroups (cov_alu module is in cov_alu.sv)
  bind alu cov_alu u_cov (.*);

endmodule
