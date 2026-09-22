// Blackbox declaration for the OpenRAM sky130_sram_1kbyte_1rw1r_32x256_8 macro.
//
// Ports only, no body — the same pattern as design/demo_synth_macro. The RTL
// frontend needs a module for demo_tiny_alu_subsys_mem's instance to bind to;
// everything else about this block comes from the views the download script
// fetches into pdk/sky130_sram/:
//
//   .lef                     placeable extent, pin geometry, power pins
//   _TT_1p8V_25C.lib         timing arcs and the setup/hold checks
//   .gds                     layout, streamed out by KLayout
//   .v                       behavioural model, for simulation only
//
// The behavioural model is deliberately NOT what synthesis reads. Handing
// OpenROAD a Verilog module with the same name as a LEF/Liberty master can lose
// the master (see synth/demo_synth_macro/README.md), and a 256 x 32 memory
// array elaborated into the netlist would be nonsense besides.
//
// The port list must match the macro's exactly; it is transcribed from
// pdk/sky130_sram/sky130_sram_1kbyte_1rw1r_32x256_8.v, whose USE_POWER_PINS
// section is omitted because the power pins are connected by the PDN, not by
// the netlist.

`timescale 1ns/10ps

(* blackbox *)
module sky130_sram_1kbyte_1rw1r_32x256_8 (
  // Port 0: RW
  input  wire        clk0,
  input  wire        csb0,
  input  wire        web0,
  input  wire [3:0]  wmask0,
  input  wire [7:0]  addr0,
  input  wire [31:0] din0,
  output wire [31:0] dout0,
  // Port 1: R
  input  wire        clk1,
  input  wire        csb1,
  input  wire [7:0]  addr1,
  output wire [31:0] dout1
);
endmodule
