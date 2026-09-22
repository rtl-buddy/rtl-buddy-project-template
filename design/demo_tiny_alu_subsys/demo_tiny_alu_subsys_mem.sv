// demo_tiny_alu_subsys_mem — technology wrapper for the result-history memory.
//
// One port map, two implementations, selected by a preprocessor macro:
//
//   RB_SRAM_SKY130 defined   an OpenRAM sky130_sram_1kbyte_1rw1r_32x256_8 hard
//                            macro (256 x 32, byte write mask, 1RW + 1R).
//                            Used by every sky130hd flow: the flat reference
//                            run, and the hierarchical assembly where this is
//                            the third-party macro sitting beside the two
//                            hardened partitions.
//
//   otherwise                a DEPTH-entry flop array with the same interface.
//                            Used by simulation and by the Nangate45 flow,
//                            neither of which has an SRAM compiler. Nangate45
//                            is a standard-cell-only PDK, so the memory has to
//                            map to flops there or the design cannot be built.
//
// The port map is the macro's, minus its power pins: a design that binds to the
// macro in one flow and to flops in another must present one interface, and the
// macro's is the one that cannot be changed. Active-low `csb`/`web` and the
// 4-bit byte write mask are OpenRAM's conventions.
//
// The generic build implements only the low `$clog2(DEPTH)` address bits. The
// design uses a 16-entry window, so both builds hold exactly the entries the
// CSR can address; the macro's remaining 240 words are unused, because 1 kbyte
// is the smallest OpenRAM build published for sky130 and a compiled memory is
// routinely larger than the window a block actually needs.

`timescale 1ns/10ps

module demo_tiny_alu_subsys_mem #(
  // Generic-build depth. Ignored when RB_SRAM_SKY130 selects the hard macro,
  // whose depth is fixed at 256 by the compiled layout.
  parameter int DEPTH = 16
) (
  input  logic        clk,

  // Port 0 — read/write
  input  logic        csb0,      // active-low chip select
  input  logic        web0,      // active-low write enable
  input  logic [3:0]  wmask0,    // per-byte write mask
  input  logic [7:0]  addr0,
  input  logic [31:0] din0,
  output logic [31:0] dout0,

  // Port 1 — read only
  input  logic        csb1,      // active-low chip select
  input  logic [7:0]  addr1,
  output logic [31:0] dout1
);

`ifdef RB_SRAM_SKY130

  // Both clock pins take the same clock: the memory is single-domain, which is
  // what keeps the hard macro out of any CDC analysis and lets the top-level
  // clock tree drive it as one sink group.
  sky130_sram_1kbyte_1rw1r_32x256_8 u_sram (
    .clk0   (clk),
    .csb0   (csb0),
    .web0   (web0),
    .wmask0 (wmask0),
    .addr0  (addr0),
    .din0   (din0),
    .dout0  (dout0),
    .clk1   (clk),
    .csb1   (csb1),
    .addr1  (addr1),
    .dout1  (dout1)
  );

`else

  localparam int AW = $clog2(DEPTH);

  logic [31:0] mem [DEPTH];

  wire [AW-1:0] a0 = addr0[AW-1:0];
  wire [AW-1:0] a1 = addr1[AW-1:0];

  always_ff @(posedge clk) begin
    if (!csb0) begin
      if (!web0) begin
        if (wmask0[0]) mem[a0][ 7: 0] <= din0[ 7: 0];
        if (wmask0[1]) mem[a0][15: 8] <= din0[15: 8];
        if (wmask0[2]) mem[a0][23:16] <= din0[23:16];
        if (wmask0[3]) mem[a0][31:24] <= din0[31:24];
      end else begin
        dout0 <= mem[a0];
      end
    end
    if (!csb1) dout1 <= mem[a1];
  end

`endif

endmodule
