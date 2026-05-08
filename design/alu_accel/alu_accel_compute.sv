// alu_accel_compute — Compute-domain (cclk) logic for the ALU accelerator.
//
// Picks operands from one of two sources per `src_sel`:
//   src_sel = 0 → CSR-direct: takes (op,a,b) from a 1-cycle cmd_valid pulse
//   src_sel = 1 → FIFO stream: pops from the async FIFO whenever non-empty
//
// Drives one `alu` instance (instantiated via library include from
// design/sandbox/alu.sv) and emits a 1-cycle result_valid pulse with
// {y, zf, cf, nf, vf} latched on the cycle the alu produces them.
//
// `busy` is high while a command is in flight or while the FIFO has
// entries waiting to be drained.

module alu_accel_compute (
  input  logic       clk,
  input  logic       rst_n,

  // SRC bit synced from apb domain
  input  logic       src_sel,

  // CSR-direct input (from apb→cclk handshake)
  input  logic       cmd_valid,
  input  logic [2:0] cmd_op,
  input  logic [7:0] cmd_a,
  input  logic [7:0] cmd_b,

  // FIFO stream input (popped here)
  output logic       fifo_rd_en,
  input  logic [18:0] fifo_rd_data,   // {op[2:0], a[7:0], b[7:0]}
  input  logic       fifo_rd_empty,

  // Result output (to cclk→apb handshake)
  output logic        result_valid,
  output logic [7:0]  result_y,
  output logic        result_zf,
  output logic        result_cf,
  output logic        result_nf,
  output logic        result_vf,

  output logic        busy
);

  // ALU input registers
  logic       launch;
  logic [2:0] op_q;
  logic [7:0] a_q, b_q;

  // FIFO pop is one cycle ahead of alu launch (because fifo rd_data is
  // combinational, but we want to register).
  always_comb begin
    fifo_rd_en = src_sel && !fifo_rd_empty && !launch;
  end

  // Capture stage
  logic capture;
  logic [2:0] cap_op;
  logic [7:0] cap_a, cap_b;

  always_comb begin
    capture = 1'b0;
    cap_op  = '0;
    cap_a   = '0;
    cap_b   = '0;
    if (src_sel) begin
      // streaming mode: capture on accepted pop (registered next cycle)
      if (fifo_rd_en) begin
        capture = 1'b1;
        {cap_op, cap_a, cap_b} = fifo_rd_data;
      end
    end else if (cmd_valid) begin
      capture = 1'b1;
      cap_op  = cmd_op;
      cap_a   = cmd_a;
      cap_b   = cmd_b;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      launch <= 1'b0;
      op_q   <= '0;
      a_q    <= '0;
      b_q    <= '0;
    end else begin
      launch <= capture;
      if (capture) begin
        op_q <= cap_op;
        a_q  <= cap_a;
        b_q  <= cap_b;
      end
    end
  end

  // ALU has 1-cycle latency: launch -> result_valid the cycle after.
  // alu uses sync active-high rst; derive from the async-low rst_n.
  alu #(.W(8)) u_alu (
    .clk,
    .rst (~rst_n),
    .op  (op_q),
    .a   (a_q),
    .b   (b_q),
    .y   (result_y),
    .zf  (result_zf),
    .cf  (result_cf),
    .nf  (result_nf),
    .vf  (result_vf)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) result_valid <= 1'b0;
    else        result_valid <= launch;          // 1 cycle after launch
  end

  // busy: any capture pending or alu in flight or fifo non-empty in stream mode
  assign busy = capture | launch | (src_sel & ~fifo_rd_empty);

endmodule
