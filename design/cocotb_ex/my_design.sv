module my_design (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       valid_i,
  input  logic [3:0] data_i,
  output logic [4:0] count_o
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count_o <= '0;
    end else if (valid_i) begin
      count_o <= count_o + data_i;
    end
  end

endmodule
