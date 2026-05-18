// Demonstrator block for the yosys-slang elaboration frontend.
//
// The two SV-2017 features below are individually fine on the Yosys
// built-in frontend, but their *combination* — `import pkg::*` between
// `module name` and the parameter `#(...)` list — is the canonical
// `TOK_IMPORT` failure case. yosys-slang's `read_slang` accepts it.
//
// Wire up via tools/yosys-slang/SETUP_OSX.md and the synth.yaml
// alongside (`synth/demo_slang_pkg/synth.yaml`).

module demo_slang_pkg_top
  import pkg_demo_slang::*;          // SV-2017: package import in module
                                     //          header before parameters
#(
  parameter int WIDTH = DEFAULT_WIDTH
) (
  input  logic              clk,
  input  logic              rst_n,
  input  data_t             d_in,    // typedef from imported package
  output logic [WIDTH-1:0]  q_out
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q_out <= '0;
    else        q_out <= d_in;
  end

endmodule
