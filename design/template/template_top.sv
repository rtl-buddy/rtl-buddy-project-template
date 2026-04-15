// vim: set ts=2 sw=2 et :
//
// Example RTL for this template project.
//
// RTL-Buddy Design Template `template_top`
module template_top #(

  parameter WIDTH = 4

) (
  input clk,
  input rst,
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output logic[WIDTH-1:0] z
);

  always_ff @(posedge clk) begin
    if (rst) begin
      z <= '0;
    end else begin
      z <= a + b;
    end
  end

endmodule
