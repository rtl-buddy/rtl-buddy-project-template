// vim: set ts=2 sw=2 et :
//
// Functional coverage for the sandbox tiny ALU.
//
// Covergroup support in Verilator is limited, so this suite uses
// `cover property` constructs (with `bins`-equivalent semantics encoded
// as named cover labels). Each label matches a SAND-FUNC-* ID in
// `spec/demo_tiny_alu/specs.yaml` so `rb spec check-coverage` closes the loop.

module cov_alu (
  input logic         clk,
  input logic         rst,
  input logic [2:0]   op,
  input logic [7:0]   a,
  input logic [7:0]   b,
  input logic [7:0]   y,
  input logic         zf,
  input logic         cf,
  input logic         nf,
  input logic         vf
);

  logic [2:0] op_d1;
  logic [7:0] a_d1;
  always_ff @(posedge clk) begin
    op_d1 <= op;
    a_d1  <= a;
  end

  // Opcodes
  SAND_FUNC_OP_ADD: cover property (@(posedge clk) !rst && op_d1 == 3'd0 && (a_d1 != '0));
  SAND_FUNC_OP_SUB: cover property (@(posedge clk) !rst && op_d1 == 3'd1);
  SAND_FUNC_OP_AND: cover property (@(posedge clk) !rst && op_d1 == 3'd2);
  SAND_FUNC_OP_OR:  cover property (@(posedge clk) !rst && op_d1 == 3'd3);
  SAND_FUNC_OP_XOR: cover property (@(posedge clk) !rst && op_d1 == 3'd4);
  SAND_FUNC_OP_SHL: cover property (@(posedge clk) !rst && op_d1 == 3'd5);
  SAND_FUNC_OP_SHR: cover property (@(posedge clk) !rst && op_d1 == 3'd6);
  SAND_FUNC_OP_NOP: cover property (@(posedge clk) !rst && op_d1 == 3'd7 && y == '0);

  // Flag corners
  SAND_FUNC_FLAG_Z_LO: cover property (@(posedge clk) !rst && zf == 1'b0);
  SAND_FUNC_FLAG_Z_HI: cover property (@(posedge clk) !rst && zf == 1'b1);
  SAND_FUNC_FLAG_N_LO: cover property (@(posedge clk) !rst && nf == 1'b0);
  SAND_FUNC_FLAG_N_HI: cover property (@(posedge clk) !rst && nf == 1'b1);
  SAND_FUNC_FLAG_C_ADD: cover property (@(posedge clk) !rst && op_d1 == 3'd0 && cf == 1'b1);
  SAND_FUNC_FLAG_C_SUB: cover property (@(posedge clk) !rst && op_d1 == 3'd1 && cf == 1'b1);
  SAND_FUNC_FLAG_V_ADD: cover property (@(posedge clk) !rst && op_d1 == 3'd0 && vf == 1'b1);
  SAND_FUNC_FLAG_V_SUB: cover property (@(posedge clk) !rst && op_d1 == 3'd1 && vf == 1'b1);

  // Operand-A range bins
  SAND_FUNC_OPERAND_RANGE_ZERO: cover property (@(posedge clk) !rst && a_d1 == 8'h00);
  SAND_FUNC_OPERAND_RANGE_LOW:  cover property (@(posedge clk) !rst && a_d1 inside {[8'h01:8'h3F]});
  SAND_FUNC_OPERAND_RANGE_MID:  cover property (@(posedge clk) !rst && a_d1 inside {[8'h40:8'hBF]});
  SAND_FUNC_OPERAND_RANGE_HIGH: cover property (@(posedge clk) !rst && a_d1 inside {[8'hC0:8'hFE]});
  SAND_FUNC_OPERAND_RANGE_MAX:  cover property (@(posedge clk) !rst && a_d1 == 8'hFF);

  // Reset cleanliness
  SAND_FUNC_RESET: cover property (
    @(posedge clk) $fell(rst) |-> (y == '0 && zf == 1'b1 && cf == 1'b0 && nf == 1'b0 && vf == 1'b0)
  );

endmodule
