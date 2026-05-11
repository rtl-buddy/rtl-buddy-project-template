// vim: set ts=2 sw=2 et :
//
// Tiny ALU — sandbox demonstrator DUT.
//
// 8-bit operands, 3-bit opcode. Result and flags are registered.
// See spec/demo_sandbox/README.md for the authoritative specification.

module demo_sandbox_alu #(
  parameter int W = 8
) (
  input  logic            clk,
  input  logic            rst,      // sync, active-high
  input  logic [2:0]      op,
  input  logic [W-1:0]    a,
  input  logic [W-1:0]    b,
  output logic [W-1:0]    y,
  output logic            zf,       // zero
  output logic            cf,       // carry / borrow
  output logic            nf,       // negative (msb of y)
  output logic            vf        // signed overflow (ADD/SUB only)
);

  // Opcodes — keep in sync with spec/demo_sandbox/sandbox_model.py
  localparam logic [2:0] OP_ADD = 3'd0;
  localparam logic [2:0] OP_SUB = 3'd1;
  localparam logic [2:0] OP_AND = 3'd2;
  localparam logic [2:0] OP_OR  = 3'd3;
  localparam logic [2:0] OP_XOR = 3'd4;
  localparam logic [2:0] OP_SHL = 3'd5;
  localparam logic [2:0] OP_SHR = 3'd6;
  localparam logic [2:0] OP_NOP = 3'd7;

  logic [W:0]   add_ext, sub_ext;
  logic [W-1:0] y_d;
  logic         cf_d, vf_d;

  always_comb begin
    add_ext = {1'b0, a} + {1'b0, b};
    sub_ext = {1'b0, a} - {1'b0, b};
    y_d  = '0;
    cf_d = 1'b0;
    vf_d = 1'b0;
    unique case (op)
      OP_ADD: begin
        y_d  = add_ext[W-1:0];
        cf_d = add_ext[W];
        vf_d = (a[W-1] == b[W-1]) && (y_d[W-1] != a[W-1]);
      end
      OP_SUB: begin
        y_d  = sub_ext[W-1:0];
        cf_d = sub_ext[W];                       // borrow
        vf_d = (a[W-1] != b[W-1]) && (y_d[W-1] != a[W-1]);
      end
      OP_AND: y_d = a & b;
      OP_OR:  y_d = a | b;
      OP_XOR: y_d = a ^ b;
      OP_SHL: y_d = a << b[$clog2(W)-1:0];
      OP_SHR: y_d = a >> b[$clog2(W)-1:0];
      OP_NOP: y_d = '0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      y  <= '0;
      zf <= 1'b1;
      cf <= 1'b0;
      nf <= 1'b0;
      vf <= 1'b0;
    end else begin
      y  <= y_d;
      zf <= (y_d == '0);
      cf <= cf_d;
      nf <= y_d[W-1];
      vf <= vf_d;
    end
  end

endmodule
